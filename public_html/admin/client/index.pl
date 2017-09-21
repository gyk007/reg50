#! /usr/bin/perl
#
# Работа с клиентами.
#

use strict;
use warnings;
use WooF::Debug;
use DateTime;
use WooF::Server;
use ALKO::Client::Net;
use ALKO::Client::Official;
use ALKO::Client::Shop;
use ALKO::Client::Merchant;
use ALKO::RegistrationSession;
use ALKO::SendMail qw(send_mail);

my $Server = WooF::Server->new(output_t => 'JSON');

=begin nd
Constant: COUNT_PAGE_ELEMET
	Количестов элементов которое выводится на одну страницу (для постраничной навигации)
=cut
use constant {
	COUNT_PAGE_ELEMET => 8,
};

# Получить данные представителя сети
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
		my $merchant = ALKO::Client::Merchant->Get(id => $net->id_merchant);

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
		allow => ['page', 'search'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		# Позиция в выборке
		my $pos = $I->{page} ? $I->{page} * COUNT_PAGE_ELEMET : 0;

		my $clients = ALKO::Client::Net->All(SLICEN => [COUNT_PAGE_ELEMET, $pos], SORT =>['id DESC']);

		# Получаем массив с id
		my @id_official = keys %{$clients->Hash('id_official')};
		my @id_merchant = keys %{$clients->Hash('id_merchant')};

		my $official = ALKO::Client::Official->All(id => \@id_official)->Hash;
		my $merchant = ALKO::Client::Merchant->All(id => \@id_merchant)->Hash;

		for ($clients->List) {
			$_->official($official->{$_->{id_official}});
			$_->merchant($merchant->{$_->{id_merchant}});
		}

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
#   search  = string
#
$Server->add_handler(SEARCH => {
	input => {
		allow => ['action', 'search'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		# Поисковый запрос по организации
		my $q = qq{
			SELECT
				*
			FROM
				official AS o
			WHERE
				lower(o.name)
			LIKE
				lower(?)
			OR
				 o.phone
			LIKE
				?
			OR
				 o.taxcode
			LIKE
				?
			OR
				lower(o.address)
			LIKE
				lower(?)
			OR
				lower(o.regaddress)
			LIKE
				lower(?)
			OR
				o.id
			IN (SELECT
					n.id_official
				FROM
					net AS n
				WHERE
					n.id_merchant
				IN (SELECT
						m.id
					FROM
						merchant as m
					WHERE
						lower(m.name)
					LIKE
						lower(?)
					)
				)
		};

		my @search_param = (
			'o.name'       => "%$I->{search}%",
			'o.phone'      => "%$I->{search}%",
			'o.taxcode'    => "%$I->{search}%",
			'o.address'    => "%$I->{search}%",
			'o.regaddress' => "%$I->{search}%",
			'm.name'       => "%$I->{search}%",
		);

		my $search = $S->D->fetch_all($q, @search_param);

		# Достаем id official
		my @id;
		push @id, $_->{id} for @$search;

		# По id official получаем все организации
		my $clients = ALKO::Client::Net->All(id_official => \@id);

		# Временная переменная, ссылка на $clients
		my $temp = $clients->Hash('id_official');

		# Каждой организации добавляем данные из таблицы official
		for (@$search){
			$temp->{$_->{id}}->[0]->official($_) if $temp->{$_->{id}}->[0];
		}

		# Полкчаем представителей из организация
		my @id_merchant = keys %{$clients->Hash('id_merchant')};
		my $merchant = ALKO::Client::Merchant->All(id => \@id_merchant)->Hash;

		# Добавляем представителя в организацию
		for ($clients->List) {
			$_->merchant($merchant->{$_->{id_merchant}});
		}

		$O->{clients} = $clients->List;

		OK;
	},
});


# Получить данные представителя магазина
#
# GET
# URL: /client/?
#   action = shopMerchant
#   id_shop  = 1
#
$Server->add_handler(SHOP_MERCHANT => {
	input => {
		allow => ['action', 'id_shop'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);


		my $shop      = ALKO::Client::Shop->Get(id => $I->{id_shop})  or return $S->fail("NOSUCH: no such shop(id => $I->{id_net})");
		my $merchant = ALKO::Client::Merchant->Get(id => $shop->id_merchant);

		$O->{merchant} = $merchant;

		OK;
	},
});


# Поиск
#
# GET
# URL: /client/?
#   action      = registration
#   email       = string
#   id_merchant = 1
#
$Server->add_handler(REGISTRATION => {
	input => {
		allow => ['action', 'email', 'id_merchant'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $ctime = DateTime->now;
		my $dtime = DateTime->now->add(days => 2);

		my $merchant = ALKO::Client::Merchant->Get(id => $I->{id_merchant}) or return $S->fail("NOSUCH: no such merchant(id => $I->{id_merchant})");

		# Проверяем сущесвует ли такой емайл
		my $is_merchant = ALKO::Client::Merchant->Get(email => $I->{email});
		if ($is_merchant and ($is_merchant->id != $merchant->id)) {
			$is_merchant->shops;
			$is_merchant->net;
			$O->{merchant} = $is_merchant;
		} else {
			# Удаляем данные представителя
			$merchant->email($I->{email});
			$merchant->name('');
			$merchant->password('');
			$merchant->phone('');

			$merchant->Save;

			# Удаляем сессию для регистрации  если она существует
			my $old_session = ALKO::RegistrationSession->Get(id_merchant => $merchant->id);
			$old_session->Remove if $old_session;

			# Создаем токен
			my $token;
			my @all = split(//, 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890');
			map { $token .= $all[rand @all]; } (0..14);

			# Создаем сессию для регистрации
			ALKO::RegistrationSession->new({
				token       => $token,
				id_merchant => $merchant->id,
				ctime       => $ctime,
				dtime       => $dtime,
				count       => 1
			})->Save;

			#  Данные для Email
			my $email_data->{token} = $token;

			send_mail({
				template => 'reg',
				to       => $I->{email},
				subject  => 'REG50 Регистрация Клиента',
				info     => $email_data
			});
		}

		OK;
	},
});

# Получить данные представителя магазина
#
# GET
# URL: /client/?
#   action = send_mail
#   name   = string
#   email  = string
#   phone  = string
#
$Server->add_handler(SEND_MAIL => {
	input => {
		allow => ['action', 'name', 'email', 'phone'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		send_mail({
			template => 'new_client',
			to       => 'info@nixteam.ru',
			subject  => 'REG50 Регистрация',
			info     => $I
		});

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

	return ['NET_MRCHANT']   if exists $I->{action} and $I->{action} eq 'netMerchant';
	return ['SHOP_MERCHANT'] if exists $I->{action} and $I->{action} eq 'shopMerchant';
	return ['REGISTRATION']  if exists $I->{action} and $I->{action} eq 'registration';
	return ['SHOPS']         if exists $I->{action} and $I->{action} eq 'shops';
	return ['SEND_MAIL']     if exists $I->{action} and $I->{action} eq 'send_mail';
	return ['SEARCH']        if exists $I->{search} and $I->{search};

	['LIST'];
});

$Server->listen;


