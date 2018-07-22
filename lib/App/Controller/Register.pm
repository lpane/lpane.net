package App::Controller::Register;

use Moo;
use Method::Signatures;

extends 'Mojolicious::Controller';
with 'App::Controller::Role::Seats';
with 'App::Controller::Role::Attendee';
with 'App::Controller::Role::RegistrationValidator';

use Data::Dumper;

# Helpers #

method _email_already_registered {
	$self->stash( error => { email => 1 } );
	$self->stash( error_message => 'Someone has already registered with that email address.' );

	return $self->render( template => 'register' );
}

# Route Handlers #

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
	my $attendee = $self->registration->attendee( email => $fields->{email} );

	if( $attendee ) {
		# Email has already been registered
		if( $attendee->{payment_status} ) {
			return $self->_email_already_registered();
		}
	} else {
		# New registration
		$attendee = $self->registration->create( $fields );
	}

	# Set paypal id in users session
	$self->session( paypal_id => $attendee->{paypal_id} );

	# Redirect to paypal payment
	#TODO make the redirect_url dynamic for the environment
	my $payment = {
		amount => $self->event->price,
		description => 'LPANE Registration',
		redirect_url => 'http://lpane.net/register/confirm'
	};

	# Call PayPal API to create a payment
	$self->delay(
		sub {
			my ($delay) = @_;
			# Register payment with paypal
			$self->paypal( register => $payment, $delay->begin );
		},
		sub {
			my ( $delay, $res ) = @_;

			# PayPal register payment response
			if( $res->code == 302 ) {
				return $self->redirect_to( $res->headers->location );
			} else {
				warn "PAYPAL ERROR: Unable to redirect to paypal!";
				warn Dumper $res;
				warn Dumper $attendee;

				$self->stash( error_message => 'We were unable to redirect you to paypal. Please try again. If you are still having issues let me know. Shoot an email to chris.handwerker@gmail.com' );
				return $self->render( template => 'register' );
			}
		}
	);
}

method confirm {
	$self->stash( title => 'Confirmation' );

 	$self->delay(
 		sub {
 			my ($delay) = @_;
 			$self->paypal( process => {}, $delay->begin );
 		},
 		sub {
 			my ( $delay, $res ) = @_;

			if( $res->code == 200 ) {
				$self->registration->set_paid( paypal_id => $self->session('paypal_id') );
				$self->stash( success_message => "You have successfully registered for" . $self->event->title . "!" );
				return $self->render( template => 'register', seats => $self->seats );
			} else {
				warn "PAYPAL ERROR: Unable to complete payment for: " . $self->session('paypal_id');
				$self->stash( error_message => 'Something went wrong with your payment. Please try again. If you are still having issues let me know. Shoot an email to chris.handwerker@gmail.com' );
				return $self->render( template => 'register', seats => $self->seats );
			}
 		}
 	);
}
1;
