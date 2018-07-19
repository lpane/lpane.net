package App::Controller::Role::Seats;

use Moo::Role;
use Method::Signatures;

method seats {
    return $self->event->seats - $self->registration->seats;
}
1;
