package App::Model::Server::Ark;

use Moose;
use namespace::autoclean;

extends 'App::Model::Server';

augment '_uri' => sub {
	my ($self) = @_;
	return "/api/listplayers";
};

augment '_key' => sub {
	my ($self) = @_;
	return $self->type;
};

sub type {
	my ($self) = @_;
	return "ark";
}

1;
