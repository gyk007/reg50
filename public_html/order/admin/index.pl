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

my $Server = ALKO::Server->new(output_t => 'JSON', auth => 1);


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
#
$Server->add_handler(LIST => {
	input => {
		allow => [],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);
		my $orders = ALKO::Order->All;

		for (@{$orders->List}) {
			$_->status;
		}

		$O->{orders} = $orders->List;
		OK;
	},
});

$Server->dispatcher(sub {
	my $S = shift;
	my $I = $S->I;
	return ['ORDER'] if exists $I->{action} and $I->{action} eq 'order';

	['LIST'];
});

$Server->listen;