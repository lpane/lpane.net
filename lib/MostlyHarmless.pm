package MostlyHarmless;

use Mojo::Base 'Mojolicious';
use Mojo::Redis2;
use Mojo::JSON qw( decode_json encode_json );

use LWP::UserAgent;

use MostlyHarmless::Model::Event;

sub startup {
	my ($self) = @_;

	$self->defaults({
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

	$self->helper( event => sub { state $event = MostlyHarmless::Model::Event->new() } );
	$self->helper( redis => sub { state $redis = Mojo::Redis2->new() } );

	$self->helper( getArkPlayers => sub {
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
	});

	my $r = $self->routes;
	$r->route('/')->to('main#index');
}
1;
