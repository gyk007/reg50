#! /usr/bin/perl
#
# Работа с клиентами.
#

use strict;
use warnings;

use WooF::Server;
use ALKO::Client::Net;

my $Server = WooF::Server->new(output_t => 'JSON');

# Список организаций
#
# GET
# URL: /client/
#
$Server->add_handler(LIST => {
	input => {
		allow => ['action', product =>[qw/ id quantity /]],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);
		my $clients = ALKO::Client::Net->All;

		$_->official for $clients->List;

		$O->{clients} = $clients->List;
		OK;
	},
});

$Server->dispatcher(sub {
	my $S = shift;
	my $I = $S->I;

	['LIST'];
});

$Server->listen;