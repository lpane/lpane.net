package App::Model::Registration;

use Moose;
use Method::Signatures;

use namespace::autoclean;

has 'dbh' => (
    is => 'ro',
    required => 1
);

has 'seats' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_seats'
);

method _build_seats {
    my $sth = $self->dbh->prepare('SELECT COUNT(*) FROM paid');
    $sth->execute();

    my ($seats) = $sth->fetchrow_array();

    return $seats;
}
1;
