
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
use ALKO::Client::File;
use ALKO::SendMail qw(send_mail);

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
			$shop->net;
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


# Получить файлы организции
#
# GET
# URL: /client/?
#   action = files
#
$Server->add_handler(GET_FILES => {
	input => {
		allow => ['action'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $merchant = ALKO::Client::Merchant->Get(id => $O->{SESSION}->id_merchant) or return $S->fail("NOSUCH: Can\'t get Merchant: no such merchant(id => $O->{SESSION}->id_merchant)");
		$merchant->net;
		my $taxcode = $merchant->{net}{official}{taxcode};

		my $files;
		$files = ALKO::Client::File->All(taxcode => $taxcode)->List if $taxcode;

		$O->{files} = $files;

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

# Поиск
#
# GET
# URL: /client/?
#   action      = send_mail
#   text        = string
#
$Server->add_handler(SEND_MAIL => {
	input => {
		allow => ['action', 'text'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $email_data;

		my $shop     = ALKO::Client::Shop->Get(id => $O->{SESSION}->id_shop);
		my $merchant = ALKO::Client::Merchant->Get(id => $O->{SESSION}->id_merchant);

		$shop->official;
		$shop->net;

		$email_data->{text}     = $I->{text};
		$email_data->{shop}     = $shop->{official}{name};
		$email_data->{net}      = $shop->{net}{official}{name};
		$email_data->{merchant} = $merchant->name;

		send_mail({
			template => 'contact',
			to       => 'info@nixteam.ru',
			subject  => 'REG50 Вопрос от клиента',
			info     => $email_data
		});

		OK;
	},
});

$Server->dispatcher(sub {
	my $S = shift;
	my $I = $S->I;

	return ['SELECT_SHOP']  if exists $I->{action} and $I->{action} eq 'select_shop';
	return ['GET_REG_DATA'] if exists $I->{action} and $I->{action} eq 'get_reg_data';
	return ['REGISTRATION'] if exists $I->{action} and $I->{action} eq 'registration';
	return ['SEND_MAIL']    if exists $I->{action} and $I->{action} eq 'send_mail';
	return ['GET_FILES']    if exists $I->{action} and $I->{action} eq 'files';

	['MERCHANT'];

});

$Server->listen;