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

method generate_id( $length ) {
    my @chars = ('A' .. 'Z', 'a' .. 'z', '0' .. '9');
    my $id;

    for( 1..$length ) {
        $id .= $chars[rand @chars];
    }

    return $id;
}

method create( $params ) {
	my $sth;

	# Generate a paypal_id
	my $paypal_id = $self->generate_id(32);

	# Add new registrant to the register table
	$sth = $self->{dbh}->prepare("INSERT INTO attendees(email, firstname, lastname, handle, paypal_id) VALUES (?,?,?,?,?)");
	$sth->execute( $params->{email}, $params->{firstname}, $params->{lastname}, $params->{handle}, $paypal_id );

	return $paypal_id;

}

method status( :$email, :$paypal_id ) {
    my $sth;
    my $query = "SELECT a.user_id, a.email, a.firstname, a.lastname, a.handle, a.paypal_id, IFNULL(p.user_id, 0) AS payment_status FROM attendees a LEFT JOIN paid p ON a.user_id=p.user_id";

    if( defined $paypal_id ) {
        $sth = $self->{dbh}->prepare( $query . " WHERE a.paypal_id = ?" );
        $sth->execute( $paypal_id );

        return $sth->fetchrow_hashref();
    } elsif( defined $email ) {
        $sth = $self->{dbh}->prepare( $query . " WHERE a.email = ?" );
        $sth->execute( $email );

        return $sth->fetchrow_hashref();
    } else {
        # Return a list of all registered attendees
        $sth = $self->{dbh}->prepare( $query );
        $sth->execute();

        my @attendees;

        while( my $row = $sth->fetchrow_hashref() ) {
            push( @attendees, $row );
        }

        return \@attendees;
    }
}
1;
