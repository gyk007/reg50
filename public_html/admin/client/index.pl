#! /usr/bin/perl
#
# Работа с клиентами.
#

use strict;
use warnings;
use WooF::Debug;
use DateTime;
use WooF::Server;
use ALKO::Session;
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

# Добавляем существуещего представителя в сеть
#
# GET
# URL: /client/?
#   action = add_merchant_to_net
#   id_net     = 1
#   id_merchant = 1
#
$Server->add_handler(ADD_MERCHANT_TO_NET => {
	input => {
		allow => ['action', 'id_merchant', 'id_net'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $net      = ALKO::Client::Net->Get(id => $I->{id_net})           or return $S->fail("NOSUCH: no such net(id => $I->{id_net})");
		my $merchant = ALKO::Client::Merchant->Get(id => $I->{id_merchant}) or return $S->fail("NOSUCH: no such merchant(id => $I->{id_merchant})");

		# Если представитель уже есть в магазинах сети то удаляем его из этих магазинов
		my $shops = ALKO::Client::Shop->All(id_net => $net->id)->List;
		$merchant->shops;
		for my $merch_shop (@{$merchant->{shops}}) {
			for my $shop (@$shops) {
				if ($merch_shop->id == $shop->id) {
					$shop->official;
					# Получаем alkoid чтобы получить дефолтного менеджера
					my $alkoid = $shop->{official}{alkoid};
					# Получаем дефолтного менеджера
					my $default_merchant = ALKO::Client::Merchant->Get(alkoid => $alkoid);
					# Сохраняем дефолтного менеджера
					$shop->id_merchant($default_merchant->id);
					$shop->Save;
				}
			}
		}

		# Привязываем менеджера к сети
		$net->id_merchant($merchant->id);
		$net->Save;

		OK;
	},
});

# Добавляем существуещего представителя в торговую точку
#
# GET
# URL: /client/?
#   action      = add_merchant_to_shop
#   id_shop     = 1
#   id_merchant = 1
#
$Server->add_handler(ADD_MERCHANT_TO_SHOP => {
	input => {
		allow => ['action', 'id_merchant', 'id_shop'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $shop     = ALKO::Client::Shop->Get(id => $I->{id_shop})         or return $S->fail("NOSUCH: no such shop(id => $I->{id_shop})");
		my $merchant = ALKO::Client::Merchant->Get(id => $I->{id_merchant}) or return $S->fail("NOSUCH: no such merchant(id => $I->{id_merchant})");
		$merchant->shops;

		# Проверяем есть ли доступ к магазину у менеджера
		my $is_access_to_this_shop = 0;
		for(@{$merchant->{shops}}) {
			$is_access_to_this_shop = 1 if $_->id == $shop->id;
		}

		# Привязываем менеджера к магазину
		$shop->id_merchant($merchant->id) unless $is_access_to_this_shop;

		OK;
	},
});

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

# Получаем всех представителей у каторых есть email
#
# GET
# URL: /client/?
#   action = get_merchant_list
#
$Server->add_handler(MERHATN_LIST => {
	input => {
		allow => ['action'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $merchant_list = ALKO::Client::Merchant->All(email => {})->List;

		# Получаем организаии представителя,
		# и меняем поле password, так как пароль мы не хешируем
		for (@$merchant_list) {
			$_->net;
			$_->{password} = 1 if     $_->{password};
			$_->{password} = 0 unless $_->{password};
		}

		$O->{merchant_list} = $merchant_list;

		OK;
	},
});

# Удалить представителя из сети или магазина
#
# GET
# URL: /client/?
#   action = delete_merchant_from
#   id_merchant  = 1
#
$Server->add_handler(DELETE_MERCHANT_FROM => {
	input => {
		allow => ['action', 'id_merchant', 'id_net', 'id_shop'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $merchant = ALKO::Client::Merchant->Get(id => $I->{id_merchant}) or return $S->fail("NOSUCH: no such merchant (id => $I->{id_net})");

		# В зависимости откуда удаляем либо из сети либо из магазина
		my $shop_or_net;
		$shop_or_net = ALKO::Client::Shop->Get(id => $I->{id_shop}) or return $S->fail("NOSUCH: no such shop(id => $I->{id_shop})") if     $I->{id_shop};
		$shop_or_net = ALKO::Client::Net->Get(id => $I->{id_net})   or return $S->fail("NOSUCH: no such net(id => $I->{id_net})")   unless $I->{id_shop};
		return $S->fail("NOSUCH: no such net or shop")  unless $shop_or_net;

		# Получаем реквизиты, в этих реквизитах хранится alkoid
		# По этому параметру можно получить дефолтного представителя
		$shop_or_net->official;
		my $alkoid = $shop_or_net->{official}{alkoid};

		# Получаем дефолтного менеджера
		my $default_merchant = ALKO::Client::Merchant->Get(alkoid => $alkoid) or return $S->fail("NOSUCH: no such merchant (alkoid => $alkoid)");

		# Отвязываем от сети или магазина текущего менеджера, и привязываем дефолтного
	 	$shop_or_net->id_merchant($default_merchant->id);
		$shop_or_net->Save;

		# Проверяем есть ли у этого менеджера магазины или сети
		# Если нет, то удалим этого менеджера
		my $net_list  = ALKO::Client::Net->All(id_merchant => $merchant->id)->List;
		my $shop_list = ALKO::Client::Shop->All(id_merchant => $merchant->id)->List;

		unless (scalar @$net_list and scalar @$shop_list) {
			# Удаляем все сессии
			my $session = ALKO::Session->All(id_merchant => $merchant->id)->List;
			$_->Remove for @$session;

			my $reg_session = ALKO::RegistrationSession->All(id_merchant => $merchant->id)->List;
			$_->Remove for @$reg_session;

			# Удаляем представителя если это не дефолтный представитель
			$merchant->Remove unless $merchant->alkoid;
		}

		OK;
	},
});

# Удалить представителя из сети или магазина
#
# GET
# URL: /client/?
#   action = delete_merchant_from
#   id_merchant  = 1
#
$Server->add_handler(DELETE_MERCHANT => {
	input => {
		allow => ['action', 'id_merchant'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $merchant = ALKO::Client::Merchant->Get(id => $I->{id_merchant}) or return $S->fail("NOSUCH: no such merchant (id => $I->{id_net})");

	 	# Удаляем представителя из сетей
		my $net_list  = ALKO::Client::Net->All(id_merchant => $merchant->id)->List;
		for (@$net_list) {
			$_->official;

			my $alkoid = $_->{official}{alkoid};
			my $default_merchant = ALKO::Client::Merchant->Get(alkoid => $alkoid) or return $S->fail("NOSUCH: no such merchant (alkoid => $alkoid)");

			$_->id_merchant($default_merchant->id);
			$_->Save;
		}

		# Удаляем представителя из магазинов
		my $shop_list = ALKO::Client::Shop->All(id_merchant => $merchant->id)->List;
		for (@$shop_list) {
			$_->official;

			my $alkoid = $_->{official}{alkoid};
			my $default_merchant = ALKO::Client::Merchant->Get(alkoid => $alkoid) or return $S->fail("NOSUCH: no such merchant (alkoid => $alkoid)");

			$_->id_merchant($default_merchant->id);
			$_->Save;
		}

		# Удаляем старые сессии
		my $old_reg_session = ALKO::RegistrationSession->All(id_merchant => $merchant->id)->List;
		$_->Remove for @$old_reg_session;
		my $old_session = ALKO::Session->All(id_merchant => $merchant->id)->List;
		$_->Remove for @$old_session;

		# Удаляем представителя
		$merchant->Remove;

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
		allow => [],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $nets = ALKO::Client::Net->All;

		# Получаем массив с id
		my @id_official = keys %{$nets->Hash('id_official')};
		my @id_merchant = keys %{$nets->Hash('id_merchant')};

		my $official = ALKO::Client::Official->All(id => \@id_official)->Hash;
		my $merchant = ALKO::Client::Merchant->All(id => \@id_merchant)->Hash;

		for ($nets->List) {
			$_->official($official->{$_->{id_official}});
			$_->merchant($merchant->{$_->{id_merchant}});
		}

		$O->{net_list} = $nets->List;

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

# Регистрация
#
# GET
# URL: /client/?
#   action      = registration
#   email       = string
#   id_merchant = 1
#   id_net      = 1
#   id_shop     = 1
#
$Server->add_handler(REGISTRATION => {
	input => {
		allow => ['action', 'email', 'id_merchant', 'id_net', 'id_shop'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $ctime = DateTime->now;
		my $dtime = DateTime->now->add(days => 2);

		my $merchant = ALKO::Client::Merchant->Get(id => $I->{id_merchant}) or return $S->fail("NOSUCH: no such merchant(id => $I->{id_merchant})");

		# торнговая точка или сеть, в зависимости к чему привязываем представителя
		my $shop_or_net;
		$shop_or_net = ALKO::Client::Shop->Get(id => $I->{id_shop}) or return $S->fail("NOSUCH: no such shop(id => $I->{id_shop})") if     $I->{id_shop};
		$shop_or_net = ALKO::Client::Net->Get(id => $I->{id_net})   or return $S->fail("NOSUCH: no such net(id => $I->{id_net})")   unless $I->{id_shop};
		return $S->fail("NOSUCH: no such net or shop")  unless $shop_or_net;

		# Проверяем сущесвует ли такой емайл
		my $is_merchant = ALKO::Client::Merchant->Get(email => $I->{email});
		# Если существует такой клиент, и его id не равен id текущего представителя - возвращаем этого представителя
		if ($is_merchant and ($is_merchant->id != $merchant->id)) {
			$is_merchant->shops;
			$is_merchant->net;
			$O->{is_merchant} = $is_merchant;
		} else {
			# Проверяем дефолтный ли это представитель
			# Это тот у кторого есть alkoid, который совпадает с alkoid организации или магазина
			unless ($merchant->alkoid) {
				# Удаляем данные представителя
				$merchant->email($I->{email});
				$merchant->name(undef);
				$merchant->password(undef);
				$merchant->phone(undef);

				# Удаляем сессию для регистрации  если она существует
				my $old_session = ALKO::RegistrationSession->Get(id_merchant => $merchant->id);
				$old_session->Remove if $old_session;
			} else {
				# Создаем нового менеджера
				$merchant = ALKO::Client::Merchant->new({
					email => $I->{email}
				});
				$merchant->Save;

				# Добавляем ногвого менеджера в сеть или магазин
				$shop_or_net->id_merchant($merchant->id);
				$shop_or_net->Save;
			}

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

			$O->{merchant} = $merchant;
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
			to       => 'grd77@bis100.ru',
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

		for (@{$shops->List}) {
			$_->merchant;
			$_->official;
		};

		$O->{shops} = $shops->List;

		OK;
	},
});

$Server->dispatcher(sub {
	my $S = shift;
	my $I = $S->I;

	return ['NET_MRCHANT']          if exists $I->{action} and $I->{action} eq 'netMerchant';
	return ['SHOP_MERCHANT']        if exists $I->{action} and $I->{action} eq 'shopMerchant';
	return ['REGISTRATION']         if exists $I->{action} and $I->{action} eq 'registration';
	return ['DELETE_MERCHANT_FROM'] if exists $I->{action} and $I->{action} eq 'delete_merchant_from';
	return ['DELETE_MERCHANT']      if exists $I->{action} and $I->{action} eq 'delete_merchant';
	return ['SHOPS']                if exists $I->{action} and $I->{action} eq 'shops';
	return ['SEND_MAIL']            if exists $I->{action} and $I->{action} eq 'send_mail';
	return ['ADD_MERCHANT_TO_NET']  if exists $I->{action} and $I->{action} eq 'add_merchant_to_net';
	return ['ADD_MERCHANT_TO_SHOP']	if exists $I->{action} and $I->{action} eq 'add_merchant_to_shop';
	return ['MERHATN_LIST']	        if exists $I->{action} and $I->{action} eq 'get_merchant_list';
	return ['SEARCH']               if exists $I->{search} and $I->{search};

	['LIST'];
});

$Server->listen;


