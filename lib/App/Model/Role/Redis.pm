package App::Model::Role::Redis;

use Moose::Role;

use Redis;

sub redis {
	my ($self) = @_;

	return $self->{redis} ||= Redis->new( reconnect => 5, every => 100_000 );
}
1;
