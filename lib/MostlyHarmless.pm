package MostlyHarmless;

use strict;
use DBI;

sub new {
	my ($class, $args) = @_;
	my $self = {};

	$self->{dbh} = DBI->connect('dbi:mysql:mhlan', 'mhlan') or die;

	return bless( $self, $class );
}
1;
