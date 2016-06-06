#!/usr/bin/env perl

use Mojolicious::Lite;
use Mojo::JSON qw( decode_json encode_json );
use Mojo::Redis2;

use FindBin;
use JSON::Schema;
use Business::PayPal;
use MIME::Lite;
use LWP::UserAgent;

use lib "$FindBin::Bin/lib";
use MostlyHarmless::Register;

# ALL GLORY TO HYPNOTOAD
app->config(
	hypnotoad => {
		listen	=> ['http://*:8081'],
		proxy	=> 1
	}
);

app->defaults({
	sidebar	=> [
		{ name => "Home", href	=> "/" },
		{ name => "Register", href	=> "/register" },
		{ name => "Games", href	=> "/games" },
		{ name => "About", href => "/about" }
	],
	error   => {},
	fields  => {},
	header  => 1,
	autosubmit => 0
});

helper redis => sub {
	my ($c) = @_;

	$c->stash->{redis} ||= Mojo::Redis2->new();
};

helper event => sub {
	my ($c) = @_;

	if( !defined $c->stash->{event} ) {
		# Lazy load event details
		my $event = $c->_getConfig('event');

		$event->{reg_open_date} = Mojo::Date->new( $event->{reg_open_date} )->epoch;
		$event->{reg_close_date} = Mojo::Date->new( $event->{reg_close_date} )->epoch;

		my $current_time = Mojo::Date->new()->epoch;

		if( $event->{reg_open_date} <= $current_time && $current_time <= $event->{reg_close_date} ) {
			$event->{open} = 1;
		} else {
			return {
				open => 0
			};
		}

		# Load game definitions
		my @games;
		foreach my $game ( @{ $event->{games} } ) {
			push( @games, $c->games->{ $game } );
		}

		$event->{games} = \@games;

		$c->stash( event => $event );
	}

	return $c->stash->{event};
};

helper games => sub {
	my ($c) = @_;

	if( !defined $c->stash->{games} ) {
		$c->stash( games => $c->_getConfig('games') );
	}

	return $c->stash->{games};
};

helper getArkPlayers => sub {
	my ($c, $host) = @_;

	my $key = "mhlan:servers:ark:$host";

	# Grab players out of stash or redis key
	my $players_json = $c->stash->{ $key } || $c->redis->get( $key );

	my $players;

	if( $players_json ) {
		# Use cached players list
		$players = decode_json( $players_json );
	} else {
		# If nothing found in stash or redis query API for list of ark players
		my $ua = LWP::UserAgent->new();
		$ua->timeout(5);

		my $response = $ua->get("http://$host.mhclan.net/api/listplayers");

		if( $response->is_success ) {
			my $players_json = $response->decoded_content;

			# Cache players in redis with expire
			$c->redis->set( $key, $players_json );
			$c->redis->expire( $key, 60 );

			$players = decode_json( $players_json );
		} else {
			app->log->warn( "Error getting player list from $host: " . $response->status_line );
			$players = { 'players' => [] };
		}
	}

	return @{ $players->{players} };
};

helper _getConfig => sub {
	my ($c, $name) = @_;

	my $file = Mojo::Asset::File->new( path => "config/$name.json" );
	return decode_json( $file->slurp );
};

any '/' => sub {
	my ($c) = @_;

	$c->stash( title => 'Home', header => 0 );
	$c->render( template => 'index' );
};

any '/games' => sub {
	my ($c) = @_;

	$c->stash( title => 'Games' );
	$c->render( template => 'games' );
};

get '/register' => sub {
	my ($c) = @_;

	my $register = MostlyHarmless::Register->new();
	my $available_seats = $c->event->{seats} - $register->seatsTaken();

	$c->stash( title => 'Register', available_seats => $available_seats );
	$c->render( template => 'register' );
};

post '/register' => sub {
	my ($c) = @_;

	my $register = MostlyHarmless::Register->new();
	$c->stash( available_seats => $c->event->{seats} - $register->seatsTaken() );

	my $params = $c->req->params->to_hash;

	$c->stash( title => 'Register', fields => $params );

	# JSON schema validator
	my $validator = JSON::Schema->new({
		properties	=> {
			firstname	=> {
				minLength	=> 1,
				type	=> 'string',
				error	=> 'Please provide your first name.'
			},
			lastname	=> {
				minLength	=> 1,
				type	=> 'string',
				error	=> 'Please provide your last name.'
			},
			email	=> {
				type	=> 'string',
				format	=> "email",
				error	=> 'Please provide a valid email address.'
			},
			handle	=> {
				minLength	=> 1,
				type	=> 'string',
				error	=> 'Please provide your handle.'
			}
		}
	}, format => \%JSON::Schema::FORMATS );

	my $result = $validator->validate( $params );

	if( $result ) {	# Form input valid
		my $status = $register->getStatus( email => $params->{email} );

		my $paypal_id;

		if( defined $status ) {	# Email is already registered
			if( $status->{payment_status} ) {
				# Email has already paid, display error for email field
				$c->stash( error => { email => "Someone has already registered with this email address." } );
				return $c->render( template => 'register' );

			} else {
				# Email has been registered but not been paid yet, redirect to payment page
				# with the email's assigned paypal_id
				$paypal_id = $status->{paypal_id};
			}
		} else { # New registration
			# Store newly registered user in database
			$paypal_id = $register->newReg( $params );
		}

		# Redirect user to pay page
		$c->redirect_to( "register/pay/$paypal_id" );

	} else {
		# Build an error object
		my $error_obj = {};

		foreach my $error ( $result->errors ) {
			my ($key) = $error->{property} =~ /\$\.(.+)/;	# Because JSON::Schema is dumb
			$error_obj->{ $key } = $validator->schema->{properties}->{ $key }->{error};
		}

		$c->stash( error => $error_obj );
		$c->render( template => 'register' );
	}
};

any '/register/pay/:paypal_id' => sub {
	my ($c) = @_;

	my $paypal_id = $c->param('paypal_id');

	# Check to see if the paypal_id has been marked as paid
	my $register = MostlyHarmless::Register->new();
	my $attendee = $register->getStatus( paypal_id => $paypal_id ) or return $c->reply->not_found;

	my $paypal = Business::PayPal->new();
	my $button = $paypal->button(
		business	=> $c->event->{paypal_email},
		item_name	=> 'Mostly Harmless LAN Registration',
		return		=> "http://mhlan.com/register/pay/$paypal_id",
		cancel_return	=> "http://mhlan.com",
		amount	=> $c->event->{price},
		quantity	=> 1,
		notify_url	=> "http://mhlan.com/register/verify",
		custom	=> $paypal_id
	);

	# Generate paypal pay form
	$c->stash( title => 'Payment', attendee => $attendee, paypal_button => $button, autosubmit => 1 );
	$c->render( template => 'register/pay' );
};

# Paypal will contact this end point when payment is made
any '/register/verify' => sub {
	my ($c) = @_;
	my $params = $c->req->params->to_hash;
	my $paypal_id = $params->{custom};

	my $paypal = Business::PayPal->new( id => $paypal_id );
	my ($txnstatus, $reason) = $paypal->ipnvalidate( $params );

	if( $txnstatus && $params->{payment_gross} eq $c->event->{price} ) {
		# Add user to paid table
		my $register = MostlyHarmless::Register->new();
		$register->setPaid( $paypal_id );

		my $attendee = $register->getStatus( paypal_id => $paypal_id );

		# Send out a confirmation email
		my $message = <<"BODY";
$attendee->{firstname} "$attendee->{handle}" $attendee->{lastname},

I have received your payment of \$$c->event->{price}. You are now registered for the Mostly Harmless LAN party.

Thanks,
The Mostly Harmless Robot
BODY
		my $email = MIME::Lite->new(
			From	=> 'noreply@mhlan.com',
			To		=> $attendee->{email},
			Subject	=> 'Mostly Harmless LAN - Registration Receipt',
			Data	=> $message
		);
		$email->send;
	}

	$c->respond_to( any => { text => '', status => '204' } );
};

any '/attendees' => sub {
	my ($c) = @_;

	# Get list of attendees
	my $register = MostlyHarmless::Register->new();

	$c->stash( title => 'Attendees', attendees => $register->getStatus() );
	$c->render( template => 'attendees' );
};

any '/directions' => sub {
	my ($c) = @_;

	$c->stash( title => 'Directions' );
	$c->render( template => 'directions' );
};

any '/contact' => sub {
	my ($c) = @_;

	$c->stash( title => 'Contact' );
	$c->render( template => 'contact' );
};

any '/about' => sub {
	my ($c) = @_;

	$c->stash( title => 'About' );
	$c->render( template => 'about' );
};

app->start;
