#!/usr/bin/env perl

use Mojolicious::Lite;

use JSON::Schema;
use Business::PayPal;
use MIME::Lite;

use lib '/var/www/mhlan.com/lib';
use MostlyHarmless::Register;

# ALL GLORY TO HYPNOTOAD
app->config(
	hypnotoad => {
		listen	=> ['http://*:8081'],
		proxy	=> 1
	}
);

my $settings = {
	header	=> 'August 1 @12pm - August 2 @12pm // Chester Mossman Teen Center // Lunenburg, MA // $20 Entry',
	seats	=> 30,
	price	=> '20.00',
	paypal_email	=> 'packard.brian@gmail.com',
	address	=> [
		'Chester Mossman Teen Center',
		'15 Memorial Drive',
		'Lunenburg, MA'
	],
	directions	=> 'The Teen Center is located between Lunenburg Town hall and Lunenburg Public Library. Memorial Drive runs parallel to Massachusetts Ave (route 2A) and perpendicular to Main St.',
	map	=> 'https://www.google.com/maps/dir//Chester+Mossman+Teen+Center,+15+Memorial+Dr,+Lunenburg,+MA+01462/@42.5959285,-71.7979462,12z/data=!3m1!4b1!4m9!4m8!1m0!1m5!1m1!1s0x89e3e84836bbce91:0xb20bf9597d662097!2m2!1d-71.7241293!2d42.5959522!3e0'
};

app->defaults({
	settings	=> $settings,
	sidebar	=> [
		{ name => "Home", href	=> "/" },
		{ name => "Games", href	=> "/games" },
		{ name => "Register", href	=> "/register" },
		{ name => "Attendees", href	=> "/attendees" },
		{ name => "Directions", href	=> "/directions" },
		{ name => "Contact", href	=> "/contact" }
	],
	error	=> {},
	fields	=> {},
	header	=> 1,
	autosubmit	=> 0
});


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
	my $available_seats = $settings->{seats} - $register->seatsTaken();

	$c->stash( title => 'Register', available_seats => $available_seats );
	$c->render( template => 'register' );
};

post '/register' => sub {
	my ($c) = @_;

	my $register = MostlyHarmless::Register->new();
	$c->stash( available_seats => $settings->{seats} - $register->seatsTaken() );

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
		business	=> $settings->{paypal_email},
		item_name	=> 'Mostly Harmless LAN Registration',
		return		=> "http://mhlan.com/register/pay/$paypal_id",
		cancel_return	=> "http://mhlan.com",
		amount	=> $settings->{price},
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

	if( $txnstatus && $params->{payment_gross} eq $settings->{price} ) {
		# Add user to paid table
		my $register = MostlyHarmless::Register->new();
		$register->setPaid( $paypal_id );

		my $attendee = $register->getStatus( paypal_id => $paypal_id );

		# Send out a confirmation email
		my $message = <<"BODY";
$attendee->{firstname} "$attendee->{handle}" $attendee->{lastname},

I have received your payment of \$$settings->{price}. You are now registered for the Mostly Harmless LAN party.

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

app->start;
