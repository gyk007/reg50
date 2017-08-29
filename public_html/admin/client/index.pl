#! /usr/bin/perl
#
# Работа с клиентами.
#

use strict;
use warnings;

use WooF::Server;
use ALKO::Client::Net;
use ALKO::Client::Official;

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

		# Получаем массив с id товаров
		my @id = keys %{$clients->Hash('id_official')};

		my $official = ALKO::Client::Official->All(id => \@id)->Hash;

		$_->official($official->{$_->{id_official}}) for $clients->List;

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


