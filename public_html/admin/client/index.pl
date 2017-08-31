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
use ALKO::Client::Shop;
use ALKO::Client::Merchant;
use ALKO::SendMail qw(send_mail);

my $Server = WooF::Server->new(output_t => 'JSON');

=begin nd
Constant: COUNT_PAGE_ELEMET
	Количестов элементов которое выводится на одну страницу (для постраничной навигации)
=cut
use constant {
	COUNT_PAGE_ELEMET => 8,
};

# Получить список магазинов
#
# GET
# URL: /client/?
#   action = netMerchant
#   id_net  = 1
#
$Server->add_handler(NET_MRCHANT => {
	input => {
		allow => ['action', 'id_net'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);


		my $net      = ALKO::Client::Net->Get(id => $I->{id_net})  or return $S->fail("NOSUCH: no such net(id => $I->{id_net})");
		my $merchant = ALKO::Client::Merchant->Get(id => $net->{id_merchant});

		$O->{merchant} = $merchant;

		OK;
	},
});

# Список организаций
#
# GET
# URL: /client/
# page = 1
#
$Server->add_handler(LIST => {
	input => {
		allow => ['page'],
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

		my $count_clients = ALKO::Client::Net->Count;

		# Получаем количесво страниц, округление в большую сторону
		my $page_count = int(($count_clients / COUNT_PAGE_ELEMET) +0.5);

		$O->{clients} = $clients->List;
		$O->{pages}   = $page_count;

		OK;
	},
});

# Поиск
#
# GET
# URL: /client/?
#   action  = search
#   search  = string
#
$Server->add_handler(SEARCH => {
	input => {
		allow => ['action', 'search'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $q = qq{
			SELECT
				*
			FROM
				official
			WHERE
				name
			LIKE
				?
			OR
				phone
			LIKE
				?
			OR
				taxcode
			LIKE
				?
		};

		my @search_param = (
			name    => "%$I->{search}%",
			phone   => "%$I->{search}%",
			taxcode => "%$I->{search}%",
		);

		my $search = $S->D->fetch_all($q, @search_param);

		my @id;
		push @id, $_->{id} for @$search;

		my $clients = ALKO::Client::Net->All(id_official => \@id);

		my $temp = $clients->Hash('id_official');

		for (@$search){
			$temp->{$_->{id}}->[0]->official($_) if $temp->{$_->{id}}->[0];
		}

		$O->{clients} = $clients->List;

		OK;
	},
});

# Поиск
#
# GET
# URL: /client/?
#   action = registration
#   email  = string
#
$Server->add_handler(REGISTRATION => {
	input => {
		allow => ['action', 'email'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		send_mail({
			template => 'reg',
			to       => $I->{email},
			subject  => 'REG50 Регистрация Клиента',
		});

		debug "OK";
		OK;
	},
});

# Получить список магазинов
#
# GET
# URL: /client/?
#   action = shops
#   id_net  = 1
#
$Server->add_handler(SHOPS => {
	input => {
		allow => ['action', 'id_net'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $shops = ALKO::Client::Shop->All(id_net => $I->{id_net});

		$_->official for $shops->List;

		$O->{shops} = $shops->List;

		OK;
	},
});

$Server->dispatcher(sub {
	my $S = shift;
	my $I = $S->I;

	return ['NET_MRCHANT']  if exists $I->{action} and $I->{action} eq 'netMerchant';
	return ['SEARCH']       if exists $I->{action} and $I->{action} eq 'search';
	return ['REGISTRATION'] if exists $I->{action} and $I->{action} eq 'registration';
	return ['SHOPS']        if exists $I->{action} and $I->{action} eq 'shops';

	['LIST'];
});

$Server->listen;


