package MostlyHarmless::Model::Game;

use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

use MostlyHarmless::Model::Game::Media;
use MostlyHarmless::Model::Game::Link;

with 'MostlyHarmless::Model::Role::Config';

subtype 'Media' => as class_type('MostlyHarmless::Model::Game::Media');
coerce 'Media' => from 'HashRef' => via { MostlyHarmless::Model::Game::Media->new( %{ $_ } ) };

subtype 'Link' => as class_type('MostlyHarmless::Model::Game::Link');
coerce 'Link' => from 'HashRef' => via { MostlyHarmless::Model::Game::Link->new( %{ $_ } ) };

has 'title' => (
	is  => 'ro',
	isa => 'Str',
	required => 1
);

has 'type' => (
	is  => 'ro',
	isa => 'Str',
	required => 1
);

has 'price' => (
	is  => 'ro',
	isa => 'Str',
	default => 'Free'
);

has 'description' => (
	is  => 'ro',
	isa => 'Str',
	required => 1
);

has 'media' => (
	is  => 'ro',
	isa => 'Media',
	required => 1,
	coerce   => 1
);

has 'link' => (
	is  => 'ro',
	isa => 'Link',
	required => 1,
	coerce   => 1
);

around BUILDARGS => sub {
	my ($orig, $self, $game) = @_;
	return $self->$orig( $self->_getConfig("games/$game") );
};

1;
