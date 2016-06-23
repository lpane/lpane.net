package MostlyHarmless::Model::Role::Config;

use Moose::Role;
use namespace::autoclean;

use Mojo::JSON qw( decode_json encode_json );

sub _getConfig {
	my ($self, $name) = @_;

	my $file = Mojo::Asset::File->new( path => "config/$name.json" );
	return decode_json( $file->slurp );
}
1;
