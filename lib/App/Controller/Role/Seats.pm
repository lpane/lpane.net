package App::Controller::Role::Seats;

use Moo::Role;
use Method::Signatures;

method seats {
	return $self->event->open ? $self->event->seats - $self->registration->seats : undef;
}
1;
