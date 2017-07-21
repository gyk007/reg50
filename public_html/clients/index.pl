#! /usr/bin/perl
#
# Список клиентов.
# В зависимости от входных параметров меняется состав вывода.
#

use strict;
use warnings;
use WooF::Debug;
use WooF::Server;
use ALKO::Clients;

my $Server = WooF::Server->new(output_t => 'JSON');

# Список всех клиентов
# URL: /clients/
$Server->add_handler(CLIENTS => {
	call => sub {
		my $S = shift;

		$S->O->{clients} = ALKO::Clients->All->List ;

		OK;
	},
});


$Server->dispatcher(sub {
	my $S = shift;
	my $I = $S->I;

	return [qw/ CLIENTS /];
});

$Server->listen;
