package MostlyHarmless::Model::Event;

use Moose;
use namespace::autoclean;

with 'MostlyHarmless::Model::Role::Config';

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

# TODO make games an ArrayRef[MostlyHarmless::Model::Game]
has 'games' => (
	is => 'ro',
	required => 1
);

around BUILDARGS => sub {
	my ($orig, $class) = @_;

	my $event = $class->_getConfig('event');

	$event->{reg_open_date} = Mojo::Date->new( $event->{reg_open_date} )->epoch;
	$event->{reg_close_date} = Mojo::Date->new( $event->{reg_close_date} )->epoch;

	my $current_time = Mojo::Date->new()->epoch;

	if( $event->{reg_open_date} <= $current_time && $current_time <= $event->{reg_close_date} ) {
		$event->{open} = 1;

		my $game_definitions = $class->_getConfig('games');

		# Load game definitions
		my @games;
		foreach my $game ( @{ $event->{games} } ) {
			push( @games, $game_definitions->{ $game } );
		}

		$event->{games} = \@games;
	} else {
		$event = {
			open => 0
		};
	}

	return $class->$orig( $event );
};
1;
