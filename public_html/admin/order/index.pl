#! /usr/bin/perl
#
# Работа с заказами.
#

use strict;
use warnings;

use WooF::Debug;
use DateTime;
use WooF::Server;
use ALKO::Order;
use ALKO::Order::Product;
use ALKO::Client::Shop;
use ALKO::Statistic::Shop;
use ALKO::Statistic::Net;
use ALKO::Statistic::Product;
use ALKO::Order::Status;
use JSON;

my $Server = WooF::Server->new(output_t => 'JSON');

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

		$order->products;
		$order->status;
		$order->shop;

		$O->{documents} = ALKO::Order::Document->All(id_order => $order->id)->List;
		$O->{order}     = $order;

		OK;
	},
});

# Удалить заказ
#
# GET
# URL: /order/?
#   action   = delete_order
#   order.id = 1
#
$Server->add_handler(DELETE_ORDER => {
	input => {
		allow => ['action', order =>[qw/ id /]],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);
		my $order = ALKO::Order->Get(id => $I->{order}{id}) or return $S->fail("NOSUCH: no such order(id => $I->{order}{id})");

		$order->Remove;

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

			$orders = ALKO::Order->All(id => \@id);
		} else {
			$orders = ALKO::Order->All;
		}

		for (@{$orders->List}) {
			$_->status;
			$_->shop;
		}

		$O->{orders} = $orders->List;
		OK;
	},
});

# Список заказов
#
# GET
# URL: /order/
#   action = statistic
#
$Server->add_handler(STATISTIC => {
	input => {
		allow => ['action'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $net      = ALKO::Statistic::Net->All;
		my $shop     = ALKO::Statistic::Shop->All;
		my $product  = ALKO::Statistic::Product->All;

		$O->{product}  = $product->List;
		$O->{shop}     = $shop->List;
		$O->{net}      = $net->List;

		OK;
	},
});

$Server->dispatcher(sub {
	my $S = shift;
	my $I = $S->I;
	return ['ORDER']      if exists $I->{action} and $I->{action} eq 'order';
	return ['DELETE_ORDER'] if exists $I->{action} and $I->{action} eq 'delete_order';
	return ['STATISTIC']  if exists $I->{action} and $I->{action} eq 'statistic';
	return ['ALL_STATUS'] if exists $I->{action} and $I->{action} eq 'status';

	['LIST'];
});

$Server->listen;