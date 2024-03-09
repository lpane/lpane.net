package App::Controller::Main;

use Moo;
use Method::Signatures;

extends 'Mojolicious::Controller';
with 'App::Controller::Role::Seats';

method index {

    #TODO implement format_date
	# https://metacpan.org/pod/DateTime#Formatters-And-Stringification
	$self->stash(
        title => 'Home',
        start => 'Saturday, May 4th @ 12pm',
        end => 'Sunday, May 5th @ 12pm',
        seats => $self->seats
    );

	$self->render( template => 'index' );
}

method games {
	$self->stash( title => 'Games' );
	$self->render( template => 'games' );
}

method about {
	$self->stash( title => 'About' );
	$self->render( template => 'about' );
}

method attendees {
	$self->stash( title => 'Attendees' );
	$self->render( template => 'attendees' );
}

1;
