
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


# Получить данные представителя
#
# GET
# URL: /client/
#
$Server->add_handler(MERCHANT => {
	input => {
		allow => [],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $merchant = ALKO::Client::Merchant->Get(id => $O->{SESSION}->id_merchant) or return $S->fail("NOSUCH: Can\'t get Merchant: no such merchant(id => $O->{SESSION}->id_merchant)");
		$merchant->net;
		$merchant->shops;

		my $shop;
		if ($O->{SESSION}->id_shop) {
			$shop = ALKO::Client::Shop->Get(id => $O->{SESSION}->id_shop);
			$shop->official;
		}

		$O->{USER} = $merchant;
		$O->{SHOP} = $shop;

		OK;
	},
});

# Получить данные клиента для регистрации
#
# GET
# URL: /client/?
#   action = get_reg_data
#
$Server->add_handler(GET_REG_DATA => {
	input => {
		allow => ['action'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $merchant = ALKO::Client::Merchant->Get(id => $O->{SESSION}->id_merchant) or return $S->fail("NOSUCH: Can\'t get Merchant: no such merchant(id => $O->{SESSION}->id_merchant)");

		$O->{merchant} = $merchant;

		OK;
	},
});


# Получить данные клиента для регистрации
#
# GET
# URL: /client/?
#   action      = registration
#   phone       = String
#   password    = String
#	name        = String
#
$Server->add_handler(REGISTRATION => {
	input => {
		allow => ['action', 'phone', 'password', 'name'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $merchant = ALKO::Client::Merchant->Get(id => $O->{SESSION}->id_merchant) or return $S->fail("NOSUCH: Can\'t get Merchant: no such merchant(id => $O->{SESSION}->id_merchant)");

		$merchant->phone($I->{phone});
		$merchant->password($I->{password});
		$merchant->name($I->{name});

		$merchant->Save;

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

	return ['SELECT_SHOP']  if exists $I->{action} and $I->{action} eq 'select_shop';
	return ['GET_REG_DATA'] if exists $I->{action} and $I->{action} eq 'get_reg_data';
	return ['REGISTRATION'] if exists $I->{action} and $I->{action} eq 'registration';
	['MERCHANT'];

});

$Server->listen;