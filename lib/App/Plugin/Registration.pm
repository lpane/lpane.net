package App::Plugin::Registration;
use Mojo::Base 'Mojolicious::Plugin';

use DBI;
use App::Model::Registration;

sub register {
    my ($self, $app) = @_;

    $app->helper( registration => sub {
        my $dbh = DBI->connect('DBI:mysql:lpane', 'lpane') or die 'Unable to connect to database';
        return App::Model::Registration->new({ dbh => $dbh });
    });
};
1;
