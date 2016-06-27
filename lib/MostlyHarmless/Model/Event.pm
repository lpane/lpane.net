package MostlyHarmless::Model::Event;

use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

use MostlyHarmless::Model::Game;

use Mojo::Date;

with 'MostlyHarmless::Model::Role::Config';

subtype 'ArrayOfGames' => as 'ArrayRef[MostlyHarmless::Model::Game]';
coerce 'ArrayOfGames' => from 'ArrayRef[Str]' => via { [ map { MostlyHarmless::Model::Game->new($_) } @$_ ] };

has 'open' => (
	is  => 'ro',
	isa => 'Bool',
	required => 1
);

has 'price' => (
	is  => 'ro',
	isa => 'Num',
	required => 1
);

has 'seats' => (
	is  => 'ro',
	isa => 'Int',
	required => 1
);

has 'paypal_email' => (
	is  => 'ro',
	isa => 'Str',
	required => 1
);

has 'address' => (
	is  => 'ro',
	isa => 'ArrayRef[Str]',
	required => 1
);

has 'directions' => (
	is  => 'ro',
	isa => 'Str',
	required => 1
);

has 'map' => (
	is  => 'ro',
	isa => 'Str',
	required => 1
);

has 'header' => (
	is  => 'ro',
	isa => 'Str',
	required => 1
);

has 'games' => (
	is  => 'ro',
	isa => 'ArrayOfGames',
	required => 1,
	coerce   => 1
);

around BUILDARGS => sub {
	my ($orig, $class) = @_;

	my $event = $class->_getConfig('event');

	$event->{reg_open_date} = Mojo::Date->new( $event->{reg_open_date} )->epoch;
	$event->{reg_close_date} = Mojo::Date->new( $event->{reg_close_date} )->epoch;

	my $current_time = Mojo::Date->new()->epoch;

	if( $event->{reg_open_date} <= $current_time && $current_time <= $event->{reg_close_date} ) {
		$event->{open} = 1;
	} else {
		$event = {
			open => 0
		};
	}

	return $class->$orig( $event );
};
1;
