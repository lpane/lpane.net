package App::Model::Game::Media;

use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

enum 'MediaType' => ['youtube'];

has 'type' => (
	is  => 'ro',
	isa => 'MediaType',
	required => 1
);

has 'src' => (
	is  => 'ro',
	isa => 'Str',
	required => 1
);
1;
