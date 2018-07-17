package App::Controller::Register;
use Mojo::Base 'Mojolicious::Controller';

use App::Model::Registration;

sub get {
    my ($self) = @_;

    my $available_seats = $self->event->seats - $self->registration->seats;

    $self->stash( title => 'Register', available_seats => $available_seats );
    $self->render( template => 'register' );
}
1;
