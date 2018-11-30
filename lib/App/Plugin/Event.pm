package App::Plugin::Event;
use Mojo::Base 'Mojolicious::Plugin';

use App::Model::Event;

sub register {
    my ($self, $app) = @_;

    $app->helper( event => sub {
        App::Model::Event->new();
    });
};
1;
