package App::Controller::Role::Attendee;

use Moo::Role;
use Method::Signatures;

method attendee {
	my $paypal_id = $self->session('paypal_id') || return undef;

	return $self->registration->attendee( paypal_id => $paypal_id );
}
1;
