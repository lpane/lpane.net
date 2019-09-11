package App::Model::Game;

use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

use App::Model::Game::Media;
use App::Model::Game::Link;

with 'App::Role::Config';

subtype 'Media' => as class_type('App::Model::Game::Media');
coerce 'Media' => from 'HashRef' => via { App::Model::Game::Media->new( %{ $_ } ) };

subtype 'Link' => as class_type('App::Model::Game::Link');
coerce 'Link' => from 'HashRef' => via { App::Model::Game::Link->new( %{ $_ } ) };

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
