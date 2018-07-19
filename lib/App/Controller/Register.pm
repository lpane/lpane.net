package App::Controller::Register;

use Moo;
use Method::Signatures;

extends 'Mojolicious::Controller';

use JSON::Validator;
use App::Model::Registration;

use Data::Dumper; #FIXME

###########
# Helpers #
###########

has 'validator' => (
	is => 'lazy'
);

method _build_validator {
	my $validator = JSON::Validator->new();

	$validator->schema({
		type => 'object',
		required => [ 'firstname', 'lastname', 'email', 'handle' ],
		properties => {
			firstname => { type => 'string', minLength => 1 },
			lastname => { type => 'string', minLength => 1 },
			email => { type => 'string', minLength => 1 },
			handle => { type => 'string', minLength => 1 }
		}
	});

	return $validator;
}

method available_seats {
	return $self->event->seats - $self->registration->seats;
}

method validate {
	my @errors = $self->validator->validate( $self->req->params->to_hash );

	if( @errors ) {
		my $error_obj = {};

		foreach my $error ( @errors ) {
			my ($key) = $error->path =~ /\/(.+)/;

			$error_obj->{ $key } = $error;
		}

		warn Dumper $error_obj;
	}
}

##################
# Route handlers #
##################

method get {
    $self->stash( title => 'Register', available_seats => $self->available_seats );
    $self->render( template => 'register' );
}

method submit {
    $self->stash( title => 'Register', available_seats => $self->available_seats );

	$self->validate( $self->req->params->to_hash );

    $self->render( template => 'register' );
}
1;
