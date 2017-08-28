
#! /usr/bin/perl
#
# Работа с клиентами.
#

use strict;
use warnings;
use WooF::Debug;
use ALKO::Server;
use ALKO::Client::Net;
use ALKO::Session;
use ALKO::Client::Merchant;
use ALKO::Client::Shop;

my $Server = ALKO::Server->new(output_t => 'JSON', auth => 1);


# Получить данные клиента
#
# GET
# URL: /client/
#
$Server->add_handler(CLIENT => {
	input => {
		allow => [],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $merchant = ALKO::Client::Merchant->Get(id => $O->{SESSION}->id_merchant);

		$merchant->net;
		$merchant->shops;

		$O->{USER} = $merchant;

		OK;
	},
});

# Выбор торговой точки
#
# POST
# URL: /client/?
#   action = select_shop
#   shop   = 20
#
$Server->add_handler(SELECT_SHOP => {
	input => {
		allow => ['action', 'shop'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $shop = ALKO::Client::Shop->Get(id => $I->{shop}) or return $S->fail("NOSUCH: Can\'t get Shop: no such shop(id => $I->{shop})");

		$O->{SESSION}->id_shop($shop->id)->Save;

		$shop->official;

		$O->{SHOP} = $shop;

		OK;
	},
});

$Server->dispatcher(sub {
	my $S = shift;
	my $I = $S->I;

	return ['SELECT_SHOP'] if exists $I->{action} and $I->{action} eq 'select_shop';

	['CLIENT'];

});

$Server->listen;