package App::Model::Event;

use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

use App::Model::Game;

use Mojo::Date;
use DateTime;

with 'App::Role::Config';

subtype 'ArrayOfGames' => as 'ArrayRef[App::Model::Game]';
coerce 'ArrayOfGames' => from 'ArrayRef[Str]' => via { [ map { App::Model::Game->new($_) } @$_ ] };

has 'open' => (
	is  => 'ro',
	isa => 'Bool',
	required => 1
);

has 'price' => (
	is  => 'ro',
	isa => 'Num'
);

has 'seats' => (
	is  => 'ro',
	isa => 'Int'
);

has 'paypal_email' => (
	is  => 'ro',
	isa => 'Str'
);

has 'address' => (
	is  => 'ro',
	isa => 'ArrayRef[Str]'
);

has 'website' => (
	is => 'ro',
	isa => 'Str'
);

has 'directions' => (
	is  => 'ro',
	isa => 'Str'
);

has 'map' => (
	is  => 'ro',
	isa => 'Str'
);

has 'title' => (
    is => 'ro',
    isa => 'Str'
);

has 'description' => (
    is => 'ro',
    isa => 'Str'
);

has 'header' => (
	is  => 'ro',
	isa => 'Str'
);

has 'games' => (
	is  => 'ro',
	isa => 'ArrayOfGames',
	coerce   => 1,
	default  => sub { [] }
);

has 'start_date' => (
    is => 'ro'
);

has 'end_date' => (
    is => 'ro'
);

around BUILDARGS => sub {
	my ($orig, $class) = @_;
	my $event = $class->_getConfig('event');

    # Parse start and end dates into DateTime objects
	$event->{start_date} = DateTime->from_epoch( epoch => Mojo::Date->new( $event->{start_date} )->epoch );
	$event->{end_date} = DateTime->from_epoch( epoch => Mojo::Date->new( $event->{end_date} )->epoch );

    # Parse reg open and close dates into Unix time
	$event->{reg_open_date} = Mojo::Date->new( $event->{reg_open_date} )->epoch;
	$event->{reg_close_date} = Mojo::Date->new( $event->{reg_close_date} )->epoch;

    # Current Unix time for comparison
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
