package MostlyHarmless::Model::Game::Link;

use Moose;
use namespace::autoclean;

has 'name' => (
	is  => 'ro',
	isa => 'Str',
	required => 1
);

has 'href' => (
	is  => 'ro',
	isa => 'Str',
	required => 1
);
1;
