package MostlyHarmless::Controller::Main;
use Mojo::Base 'Mojolicious::Controller';

sub index {
	my ($self) = @_;

	$self->stash( title => 'Home' );
	$self->render( template => 'index' );
}
1;
