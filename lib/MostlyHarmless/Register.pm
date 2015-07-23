package MostlyHarmless::Register;
use parent MostlyHarmless;

use strict;

# Add a new unpaid user, returns a paypal_id
sub newReg {
	my ($self, $params) = @_;
	my $sth;

	# Generate a paypal_id
	my $paypal_id = $self->_generateID(32);

	# Add new registrant to the register table
	$sth = $self->{dbh}->prepare("INSERT INTO attendees(email, firstname, lastname, handle, paypal_id) VALUES (?,?,?,?,?)");
	$sth->execute( $params->{email}, $params->{firstname}, $params->{lastname}, $params->{handle}, $paypal_id );

	return $paypal_id;
}

# Mark the attendee as paid given a paypal_id
sub setPaid {
	my ($self, $paypal_id) = @_;
	my $sth;

	# Get user ID associated with the paypal ID from unpaid table
	$sth = $self->{dbh}->prepare("SELECT user_id FROM attendees WHERE paypal_id=?");
	$sth->execute( $paypal_id );

	my ($user_id) = $sth->fetchrow_array();

	# Insert user_id in to paid table
	$sth = $self->{dbh}->prepare("INSERT INTO paid(user_id) VALUES (?)");
	$sth->execute( $user_id );

	return;
}

# Get the status of a payment along with other reg details given a paypal_id
sub getStatus {
	my ($self, %args) = @_;
	my $sth;

	my $query = "SELECT a.user_id, a.email, a.firstname, a.lastname, a.handle, a.paypal_id, IFNULL(p.user_id, 0) AS payment_status FROM attendees a LEFT JOIN paid p ON a.user_id=p.user_id";

	if( defined $args{paypal_id} ) {
		$sth = $self->{dbh}->prepare( $query . " WHERE a.paypal_id = ?" );
		$sth->execute( $args{paypal_id} );

		return $sth->fetchrow_hashref();

	} elsif( defined $args{email} ) {
		$sth = $self->{dbh}->prepare( $query . " WHERE a.email = ?" );
		$sth->execute( $args{email} );

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

sub seatsTaken {
	my ($self) = @_;

	my $sth = $self->{dbh}->prepare("SELECT COUNT(*) FROM paid");
	$sth->execute();

	my ($seats) = $sth->fetchrow_array();

	return $seats;
}

sub _generateID {
	my ($self, $length) = @_;
    my @chars = ('A' .. 'Z', 'a' .. 'z', '0' .. '9');
    my $id;

    for( 1..$length ) {
        $id .= $chars[rand @chars];
    }

    return $id;
}

1;
