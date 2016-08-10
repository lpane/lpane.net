package MostlyHarmless;

use Mojo::Base 'Mojolicious';

use MostlyHarmless::Model::Event;

sub startup {
	my ($self) = @_;

	$self->plugin('MostlyHarmless::Plugin::Defaults');	# Default application settings
	$self->plugin('MostlyHarmless::Plugin::Servers');	# Game server classes

	$self->hook( before_dispatch => sub {
		my ($c) = @_;
		# Read event config for every request
		# TODO only instantiate this for requests under the main controller
		$c->stash( event => MostlyHarmless::Model::Event->new() );
	});

	my $r = $self->routes;

	$r->route('/')->to('main#index');
	$r->route('/games')->to('main#games');
	$r->route('/about')->to('main#about');

	my $login = $r->any('/login')->to( controller => 'login' );
	$login->get('/')->to( action => 'claim_identity' );
	$login->get('/check')->to( action => 'check_identity' );
}
1;
