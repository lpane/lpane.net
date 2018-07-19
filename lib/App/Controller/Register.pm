package App::Controller::Register;

use Moo;
use Method::Signatures;

extends 'Mojolicious::Controller';
with 'App::Controller::Role::Seats';
with 'App::Controller::Role::RegistrationValidator';

method get {
	$self->stash( title => 'Register', seats => $self->seats );
	$self->render( template => 'register' );
}

method submit {
	$self->stash( title => 'Register', seats => $self->seats );

	my $fields = $self->req->params->to_hash;

	# Make sure form is valid
	if( my $validation_errors = $self->validate( $fields ) ) {
		# Render form with validation errors
		$self->stash( error => $validation_errors, fields => $fields );
		$self->render( template => 'register' );
	}

	#Check account status by email
	my $paypal_id;

	if( my $status = $self->registration->status( email => $fields->{email} ) ) {
		warn 'Email has already been registered.';
		if( $status->{payment_status} ) {
			warn 'Error: Someone has already registered with this email address.';
		} else {
			warn 'Email has been registered but not been paid yet, redirect to payment page with the account assigned paypal_id';
		}
	} else { # New registration
		warn 'Create account';
		$paypal_id = $self->registration->create( $fields );
	}

	warn 'Redirect to payment page';
	$self->redirect_to("register/pay/$paypal_id");
}

method pay {
	# https://developer.paypal.com/docs/checkout/integrate/#
	# https://developer.paypal.com/docs/checkout/how-to/server-integration/#how-a-server-integration-works

	my $paypal_id = $self->param('paypal_id');

	# Check to see if the paypal_id has already been marked as paid
	my $status = $self->registration->status( paypal_id => $paypal_id ) or return $self->reply->not_found;
}
1;
