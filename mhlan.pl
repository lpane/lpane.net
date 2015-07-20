#!/usr/bin/env perl
use Mojolicious::Lite;

any '/' => sub {
  my ($c) = @_;
  $c->render( template => 'index' );
};

any '/games' => sub {
	my ($c) = @_;
	$c->render( template => 'games' );
};

any '/register' => sub {
	my ($c) = @_;
	$c->render( template => 'register' );
};

any '/directions' => sub {
	my ($c) = @_;
	$c->render( template => 'directions' );
};

any '/sponsors' => sub {
	my ($c) = @_;
	$c->render( template => 'sponsors' );
};

any '/contact' => sub {
	my ($c) = @_;
	$c->render( template => 'contact' );
};

app->start;
