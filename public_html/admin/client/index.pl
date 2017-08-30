#! /usr/bin/perl
#
# Работа с клиентами.
#

use strict;
use warnings;
use WooF::Debug;
use WooF::Server;
use ALKO::Client::Net;
use ALKO::Client::Official;

my $Server = WooF::Server->new(output_t => 'JSON');

=begin nd
Constant: COUNT_PAGE_ELEMET
	Количестов элементов которое выводится на одну страницу (для постраничной навигации)
=cut
use constant {
	COUNT_PAGE_ELEMET => 5,
};

# Список организаций
#
# GET
# URL: /client/
#
$Server->add_handler(LIST => {
	input => {
		allow => ['action', 'page'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		# Позиция в выборке
		my $pos = $I->{page} ? $I->{page} * COUNT_PAGE_ELEMET : 0;

		my $clients = ALKO::Client::Net->All(SLICEN => [COUNT_PAGE_ELEMET, $pos], SORT =>['id DESC']);

		# Получаем массив с id товаров
		my @id = keys %{$clients->Hash('id_official')};

		my $official = ALKO::Client::Official->All(id => \@id)->Hash;

		$_->official($official->{$_->{id_official}}) for $clients->List;

		$O->{clients}       = $clients->List;
		$O->{count_clients} = ALKO::Client::Net->Count;

		OK;
	},
});

$Server->dispatcher(sub {
	my $S = shift;
	my $I = $S->I;

	['LIST'];
});

$Server->listen;


