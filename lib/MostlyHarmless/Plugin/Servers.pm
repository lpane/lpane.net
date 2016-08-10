package MostlyHarmless::Plugin::Servers;
use Mojo::Base 'Mojolicious::Plugin';

use MostlyHarmless::Model::Server::Ark;

sub register {
	my ($self, $app) = @_;

	$app->helper( servers => sub { @{ state $servers = sub {
		my ($self) = @_;
		my @servers;

		push( @servers, MostlyHarmless::Model::Server::Ark->new({
			title => "Ark: Survival - The Center",
			host  => "ark-center"
		}));

		push( @servers, MostlyHarmless::Model::Server::Ark->new({
			title => "Ark: Survival - The Island",
			host  => "ark-island"
		}));

		return \@servers;
	}->()}});
}
1;
