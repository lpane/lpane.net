package App;

use Mojo::Base 'Mojolicious';

use App::Model::Event;

sub startup {
	my ($self) = @_;

	$self->plugin('App::Plugin::Defaults');	# Default application settings
	$self->plugin('App::Plugin::Registration');
	$self->plugin('App::Plugin::Event');

	#TODO no game servers anymore. I'll bring this back later.
	#$self->plugin('App::Plugin::Servers');	# Game server classes

	$self->hook( before_dispatch => sub {
		my ($self) = @_;
		# Read event config for every request
		# TODO only instantiate this for requests under the main controller
		$self->stash( event => $self->event );
		$self->stash( registration => $self->registration );
	});

	my $r = $self->routes;

	$r->route('/')->to('main#index');
	$r->route('/games')->to('main#games');
	$r->route('/about')->to('main#about');

	my $register = $r->any('/register')->to( controller => 'register' );
	$register->post('/')->to( action => 'submit' );
	$register->get('/')->to( action => 'get' );
	$register->get('pay/:paypal_id')->to( action => 'pay' );

	#TODO account login with OpenID
	#my $login = $r->any('/login')->to( controller => 'login' );
	#$login->get('/')->to( action => 'claim_identity' );
	#$login->get('/check')->to( action => 'check_identity' );
}
1;
