package App;

use Moo;
use Method::Signatures;

extends 'Mojolicious';
with 'App::Role::Config';

method startup {
	my $config = $self->_getConfig('app');

	$self->secrets([ $config->{secret} ]);
	$self->plugin('App::Plugin::Defaults');	# Default application settings
	$self->plugin('App::Plugin::Event');
	$self->plugin('App::Plugin::Registration');
	$self->plugin('PayPal' => $config->{paypal});

	# TODO implement a custom transaction_id_mapper
	# $self->paypal->transaction_id_mapper( sub {
	# 	my ($self, $token, $transaction_id, $cb) = @_;
	# 	if( $transaction_id ) {
	# 		warn 'We should mark the transaction id here';
	# 		# EX: eval { My::DB->store_transaction_id($token => $transaction_id); };
	# 		#$self->session( transaction_id => $transaction_id );
	# 		$self->$cb($@, $transaction_id);
	# 	} else {
	# 		warn 'We should get the users transaction id here';
	# 		# EX: my $transaction_id = eval { My::DB->get_transaction_id($token)); };
	# 		#$transaction_id = $self->session('transaction_id');
	# 		$self->$cb($@, $transaction_id);
	# 	}
	# });

	#TODO no game servers anymore. I'll bring this back later.
	#$self->plugin('App::Plugin::Servers');	# Game server classes

	$self->hook( before_dispatch => sub {
		my ($self) = @_;
		# Read event config for every request
		# TODO only instantiate this for requests under the main controller
		$self->stash( event => $self->event );
		$self->stash( registration => $self->registration );
		$self->stash( paypal => $self->paypal );
	});

	my $r = $self->routes;

	$r->route('/')->to('main#index');
	$r->route('/games')->to('main#games');
	$r->route('/about')->to('main#about');

	my $register = $r->any('/register')->to( controller => 'register' );
	$register->post('/')->to( action => 'submit' );
	$register->get('/')->to( action => 'get' );
	$register->get('/confirm')->to( action => 'confirm' );

	#TODO account login with OpenID
	#my $login = $r->any('/login')->to( controller => 'login' );
	#$login->get('/')->to( action => 'claim_identity' );
	#$login->get('/check')->to( action => 'check_identity' );
}
1;
