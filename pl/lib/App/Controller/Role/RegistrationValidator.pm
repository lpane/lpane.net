package App::Controller::Role::RegistrationValidator;

use Moo::Role;
use Method::Signatures;

use JSON::Validator;

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

method validate($params) {
	my @errors = $self->validator->validate($params);

	if( @errors ) {
		my $error_obj = {};

		foreach my $error ( @errors ) {
			my ($key) = $error->path =~ /\/(.+)/;

			$error_obj->{ $key } = $error;
		}

        return $error_obj
	}

    return undef;
}

1;
