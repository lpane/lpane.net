package App::Controller::Login;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::URL;
use Net::OpenID::Consumer;

sub claim_identity {
	my ($self) = @_;

	my $claimed_identity = $self->csr->claimed_identity("http://steamcommunity.com/openid");
	my $url = $self->req->url->base->to_string;

	my $check_url = $claimed_identity->check_url(
		return_to  => "$url/login/check",
		trust_root => "$url",
		delayed_return => 1
	);

	$self->res->code(302);
	$self->redirect_to( $check_url );
}

sub check_identity {
	my ($self) = @_;

	if( !$self->csr->is_server_response ) {
		$self->app->log->error("Invalid OpenID request");
	} elsif ( $self->csr->user_cancel ) {
		# TODO return user back to previous page
		warn "User hit cancel";
	} elsif ( my $verified_identity = $self->csr->verified_identity ) {
		my $steam_id = Mojo::URL->new( $verified_identity->url )->path->parts->[2];
		warn "Got your steam_id: $steam_id";
		# TODO generate a session_id and tie it to the user's steam_id via a user object?
	} else {
		$self->app->log->error( "Error validating identity: " . $self->csr->err );
	}

	$self->res->code(302);
	$self->redirect_to("/");
}

sub csr {
	my ($self) = @_;

	# TODO make the consumer_secret unique for the user's session
	$self->{csr} ||= Net::OpenID::Consumer->new(
		ua => LWP::UserAgent->new(),
		consumer_secret => "changemeplease",
		args => $self->req->params->to_hash
	);

	return $self->{csr};
}
1;
