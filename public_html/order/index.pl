#! /usr/bin/perl
#
# Работа с заказами.
#

use strict;
use warnings;

use WooF::Debug;
use DateTime;
use ALKO::Server;
use ALKO::Order;
use ALKO::Cart;
use ALKO::Catalog::Product;
use ALKO::Client::Shop;
use ALKO::Order::Status;
use ALKO::Statistic::Shop;
use ALKO::Statistic::Net;
use ALKO::Statistic::Product;
use JSON;
use Encode;
use utf8;

my $Server = ALKO::Server->new(output_t => 'JSON', auth => 1);

# Создать заказ
#
# POST
# URL: /order/?
#   action           = add
#   order.phone      = String
#   order.address    = String
#	order.name       = String
#   order.remark     = String
#   order.email      = String
#   order.email      = 1
#
$Server->add_handler(ADD => {
	input => {
		allow => [
			'action',
			order => [qw/ phone address name remark email /],
		],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);
		my $order_data = $I->{order};
		$order_data->{id_status} = 1;

		my $shop  = ALKO::Client::Shop->Get(id => $O->{SESSION}->id_shop) or return $S->fail("NOSUCH: Can\'t get Shop: no such shop(id => $O->{SESSION}->id_shop)");
		my $cart  = ALKO::Cart->Get(id_shop => $shop->id, n => 1)         or return $S->fail("NOSUCH: Can\'t get Cart: no such cart($shop->id)");

		# Цена заказа
		my $order_price = 0;
		for (@{$cart->products($O->{SESSION}->id_shop)->List}) {
			$order_price += $_->product->price * $_->quantity;
		};

		$order_data->{id_status}   = ALKO::Order::Status->Get(name => 'new')->id;
		$order_data->{id_net}      = $shop->id_net;
		$order_data->{id_merchant} = $O->{SESSION}->id_merchant;
		$order_data->{price}       = $order_price;
		$order_data->{ctime}       = DateTime->now;
		$order_data->{id_shop}     = $shop->id;

		my $order = ALKO::Order->new($order_data)->Save or return $S->fail("NOSUCH: Can\'t create order");

		for (@{$cart->products($O->{SESSION}->id_shop)->List}) {
			my $ordrer_prod = ALKO::Order::Product->new({
				id_order   => $order->id,
				id_product => $_->{product}{id},
				price      => $_->{product}{price},
				qty        => $_->{quantity},
			})->Save;

			# Добавляем статистику товара
			my $stat_prod = ALKO::Statistic::Product->Get(id_product => $ordrer_prod->id_product);
			if ($stat_prod) {
				$stat_prod->qty($stat_prod->qty + $ordrer_prod->qty);
				$stat_prod->price($stat_prod->price + ($ordrer_prod->price * $ordrer_prod->qty));
			} else {
				$stat_prod = ALKO::Statistic::Product->new({
					id_product => $ordrer_prod->id_product,
					name    => $ordrer_prod->product->name,
					qty     => $ordrer_prod->qty,
					price   => ($ordrer_prod->price * $ordrer_prod->qty)
				});
			}
			$stat_prod->Save;
			# Удаляем товар из корзины
			$_->Remove
		};

		$order->products;
		$order->status;
		$order->shop;

		# Добавляем статистику
		# Статистика торговой точки
		my $stat_shop = ALKO::Statistic::Shop->Get(id_shop => $shop->id);
		if ($stat_shop) {
			$stat_shop->qty($stat_shop->qty + 1);
			$stat_shop->price($stat_shop->price + $order_price);
		} else {
			$stat_shop = ALKO::Statistic::Shop->new({
				id_shop => $shop->id,
				name    => $shop->official->name,
				qty     => 1,
				price   => $order_price
			});
		}
		$stat_shop->Save;

		# Статистика сети
		my $stat_net = ALKO::Statistic::Net->Get(id_net => $shop->id_net);
		if ($stat_net) {
			$stat_net->qty($stat_net->qty + 1);
			$stat_net->price($stat_net->price + $order_price);
		} else {
			$stat_net = ALKO::Statistic::Net->new({
				id_net  => $shop->id_net,
				name    => $shop->net->official->name,
				qty     => 1,
				price   => $order_price
			});
		}
		$stat_net->Save;

		$O->{order}     = $order;
		$O->{documents} = ALKO::Order::Document->All(id_order => $order->id)->List;

		OK;
	},
});


# Список всех статусов
#
# GET
# URL: /order/
#   action = status
#
$Server->add_handler(ALL_STATUS => {
	input => {
		allow => ['action'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $status = ALKO::Order::Status->All;


		$O->{status} = $status->List;
		OK;
	},
});

# Добавить документ в заказ
#
# POST
# URL: /order/?
#   action        = add_document
#   order.id      = 1
#   document.name = String
#
$Server->add_handler(ADD_DOCUMENT => {
	input => {
		allow => [
			'action',
			order     => [qw/ id /],
			document  => [qw/ name /],
		],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $order = ALKO::Order->Get($I->{order}) or return $S->fail("NOSUCH: Can\'t get Order: no such order(id => $I->{order}{id})");

		ALKO::Order::Document->new({
			id_order => $order->id,
			name     => $I->{document}{name},
			status   => 'requested',
		})->Save;

		$order->alko_sync_status(0);

		$O->{documents} = ALKO::Order::Document->All(id_order => $order->id)->List;

		OK;
	},
});

# Удалить документ в заказе
#
# POST
# URL: /order/?
#   action        = delete_document
#   order.id      = 1
#   document.name = String
#
$Server->add_handler(DELETE_DOCUMENT => {
	input => {
		allow => [
			'action',
			order     => [qw/ id /],
			document  => [qw/ name /],
		],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $order = ALKO::Order->Get($I->{order}) or return $S->fail("NOSUCH: Can\'t get Order: no such order(id => $I->{order}{id})");

		my $documnt = ALKO::Order::Document->Get(id_order => $order->id, name => $I->{document}{name}) or return $S->fail("NOSUCH: Can\'t get Document: no such document(id_order => $order->id, name => $I->{document}{name})");
		$documnt->Remove;

		$order->alko_sync_status(0);

		$O->{documents} = ALKO::Order::Document->All(id_order => $order->id)->List;

		OK;
	},
});

# Получить заказ
#
# GET
# URL: /order/?
#   action   = order
#   order.id = 1
#
$Server->add_handler(ORDER => {
	input => {
		allow => ['action', order =>[qw/ id /]],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);
		my $order = ALKO::Order->Get(id => $I->{order}{id}) or return $S->fail("NOSUCH: no such order(id => $I->{order}{id})");

		$order->products($O->{SESSION}->id_shop);
		$order->status;
		$order->shop;

		my $documents = ALKO::Order::Document->All(id_order => $order->id);

		$O->{documents} = $documents->List;
		$O->{order}     = $order;

		OK;
	},
});

# Список заказов
#
# GET
# URL: /order/
#   filter =  JSON объект с данными фильра
#
$Server->add_handler(LIST => {
	input => {
		allow => ['filter'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $orders;
		if($I->{filter}) {
			my $filter = decode_json($I->{filter});
			# Фильтр по дате
			my $where_date;
			if ($filter->{dateTo} and $filter->{dateFrom}) {
				my ($date_from, $time_from) = split('T', $filter->{dateFrom});
				my ($date_to,     $time_to) = split('T', $filter->{dateTo});

				my ($year_from, $month_from, $day_from)  = split('-', $date_from);
				my ($year_to,   $month_to,   $day_to)    = split('-', $date_to);

				$date_from = DateTime->new(
					year   => $year_from,
					month  => $month_from,
					day    => $day_from,
				) or return $S->fail("DATE: date error");

				$date_to = DateTime->new(
					year   => $year_to,
					month  => $month_to,
					day    => $day_to,
				) or return $S->fail("DATE: date error");

				# Добавляем 1 день
				$date_to = $date_to->subtract(days => -1)->strftime("%Y-%m-%d");
				$date_from = $date_from->subtract(days => -1)->strftime("%Y-%m-%d");

				$where_date = "ctime >= '$date_from' AND ctime <= '$date_to'";
			}

			# Фильтр по поисковому запросу
			my $where_search;
			if ($filter->{search}) {
				my $search_str = "lower('%$filter->{search}%')";
				$where_search  = "lower(num) LIKE $search_str";
			}

			# Фильтр по статусу
			my $where_status;
			if ($filter->{status} and ref $filter->{status} eq 'ARRAY') {
				my $status_str = join ',', @{$filter->{status}};
				$status_str = "($status_str)";
				$where_status = "id_status IN $status_str";
			}

			# Собираем массив where
			my @where_arr;
			push @where_arr, $where_date   if $where_date;
			push @where_arr, $where_search if $where_search;
			push @where_arr, $where_status if $where_status;

			# Формируем строку WHERE
			my $where_str = join ' AND ',  @where_arr;
			$where_str = "WHERE $where_str" if $where_str;

			# Запрос
			my $q = "SELECT * FROM orders $where_str";
			my $search_orders = $S->D->fetch_all($q);

			# Получаем id orders
			my @id;
			push @id, $_->{id} for @$search_orders;

			$orders = ALKO::Order->All(id => \@id, id_shop => $O->{SESSION}->id_shop)  or return $S->fail("NOSUCH: no such orders(id_merchant => $O->{SESSION}->id_merchant)");
		} else {
			$orders = ALKO::Order->All(id_shop => $O->{SESSION}->id_shop)  or return $S->fail("NOSUCH: no such orders(id_merchant => $O->{SESSION}->id_merchant)");
		}

		for (@{$orders->List}) {
			$_->status;
			$_->shop;
		}

		$O->{orders} = $orders->List;
		OK;
	},
});

$Server->dispatcher(sub {
	my $S = shift;
	my $I = $S->I;
	return ['ADD']             if exists $I->{action} and $I->{action} eq 'add';
	return ['ALL_STATUS']      if exists $I->{action} and $I->{action} eq 'status';
	return ['ORDER']           if exists $I->{action} and $I->{action} eq 'order';
	return ['ADD_DOCUMENT']    if exists $I->{action} and $I->{action} eq 'add_document';
	return ['DELETE_DOCUMENT'] if exists $I->{action} and $I->{action} eq 'delete_document';
	['LIST'];
});

$Server->listen;