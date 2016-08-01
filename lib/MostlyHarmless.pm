package MostlyHarmless;

use Mojo::Base 'Mojolicious';
use Mojo::Redis2;
use Mojo::JSON qw( decode_json encode_json );

use LWP::UserAgent;

use MostlyHarmless::Model::Event;
use MostlyHarmless::Model::Server::Ark;

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

	# Array of game server classes
	$self->helper( servers => sub { @{ state $servers = sub {
		my ($self) = @_;
		my @servers;

		push( @servers, MostlyHarmless::Model::Server::Ark->new({
			title => "Ark: Survival - The Center",
			host  => "ark-center"
		}));

		push( @servers, MostlyHarmless::Model::Server::Ark->new({
			title => "Ark: Survival - The Island",
			host  => "ark-island"
		}));

		return \@servers;
	}->()}});

	$self->hook( before_dispatch => sub {
		my ($c) = @_;
		$c->stash( event => MostlyHarmless::Model::Event->new() );
	});

	my $r = $self->routes;

	$r->route('/')->to('main#index');
	$r->route('/games')->to('main#games');
	$r->route('/about')->to('main#about');
}
1;
