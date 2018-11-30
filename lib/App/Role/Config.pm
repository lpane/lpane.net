package App::Role::Config;

use Moo::Role;
use Method::Signatures;

use Mojo::Asset::File;
use Mojo::JSON qw( decode_json encode_json );

method _getConfig( $name ) {
	my $file = Mojo::Asset::File->new( path => "config/$name.json" );
	return $file->size ? decode_json( $file->slurp ) : undef;
}
1;
