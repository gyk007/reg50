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

# Список заказов
#
# GET
# URL: /order/
#   status   =  (JSON) массив с id статусов
#
$Server->add_handler(LIST => {
	input => {
		allow => ['status'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $orders;
		if($I->{status}) {
			my $id_stauts = decode_json($I->{status});
			$orders = ALKO::Order->All(id_status => $id_stauts);
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
	return ['STATISTIC']  if exists $I->{action} and $I->{action} eq 'statistic';
	return ['ALL_STATUS'] if exists $I->{action} and $I->{action} eq 'status';

	['LIST'];
});

$Server->listen;