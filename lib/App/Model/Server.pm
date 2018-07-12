package App::Model::Server;

use Moose;
use namespace::autoclean;

with 'App::Model::Role::Redis';

use LWP::UserAgent;
use JSON qw( decode_json encode_json );

has 'title' => (
	is  => 'ro',
	isa => 'Str',
	required => 1
);

has 'host' => (
	is  => 'ro',
	isa => 'Str',
	required => 1,
	reader   => '_host'
);

sub players {
	my ($self) = @_;

	# Grab players json out of redis
	my $players_json = $self->redis->get( $self->_key );

	my $players;

	if( $players_json ) {
		# Use cached players list
		$players = decode_json( $players_json );
	} else {
		# If nothing found in stash or redis query API for list of ark players
		my $ua = LWP::UserAgent->new();
		$ua->timeout(5);

		my $response = $ua->get( $self->_uri );

		if( $response->is_success ) {
			my $players_json = $response->decoded_content;

			# Cache players in redis with expire
			$self->redis->set( $self->_key, $players_json );
			$self->redis->expire( $self->_key, 60 );

			$players = decode_json( $players_json );
		} else {
			# TODO figure out how to use Mojolicious logging here
			#app->log->warn( "Error getting player list from $host: " . $response->status_line );
			$players = { 'players' => [] };
		}
	}

	return @{ $players->{players} };
}

sub _uri {
	my ($self) = @_;
	return "http://" . $self->_host . ".mhclan.net" . inner();
}

sub _key {
	my ($self) = @_;
	return "mhlan:servers:" . inner() . ":" . $self->_host;
}

1;
