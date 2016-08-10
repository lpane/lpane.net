package MostlyHarmless::Plugin::Defaults;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
	my ($self, $app) = @_;

	$app->defaults({
		sidebar	=> [
			{ name => "Home", href	=> "/" },
			{ name => "Register", href	=> "/register" },
			{ name => "Games", href	=> "/games" },
			{ name => "About", href => "/about" }
		],
		error   => {},
		fields  => {},
		header  => 1,
		autosubmit => 0
	});
}
1;
