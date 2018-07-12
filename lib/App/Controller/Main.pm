package App::Controller::Main;
use Mojo::Base 'Mojolicious::Controller';

sub index {
	my ($self) = @_;

	$self->stash( title => 'Home' );
	$self->render( template => 'index' );
}

sub games {
	my ($self) = @_;

	$self->stash( title => 'Games' );
	$self->render( template => 'games' );
}

sub about {
	my ($self) = @_;

	$self->stash( title => 'About' );
	$self->render( template => 'about' );
}

1;
