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
use ALKO::Cart;
use ALKO::Catalog::Product;
use ALKO::Client::Shop;

my $Server = WooF::Server->new(output_t => 'JSON');

# Добавить товар в корзину
#
# POST
# URL: /order/?
#   action           = add
#   order.phone      = String
#   order.address    = String
#	order.name       = String
#   order.remark     = String
#   order.email      = String
#   rder.email       = 1
#   cart.id_merchant = 1
#   order.id_shop    = 2
#
$Server->add_handler(ADD => {
	input => {
		allow => [
			'action',
			order => [qw/ phone address name remark email id_shop price/],
			cart  => [qw/ id_merchant n /],
		],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);
		my $order_data = $I->{order};
		$order_data->{id_status} = 1;

		return $S->fail("NOSUCH: Can\'t get Shop: no such shop(id => $order_data->{id_shop})") unless $order_data->{id_shop};

		my $shop  = ALKO::Client::Shop->Get(id => $order_data->{id_shop})  or return $S->fail("NOSUCH: Can\'t get Shop: no such shop(id => $order_data->{id_shop})");
		my $cart  = ALKO::Cart->Get($I->{cart})                            or return $S->fail("NOSUCH: Can\'t get Cart: no such cart(id_merchant => $I->{cart}{id_merchant}, n => $I->{cart}{n})");

		# Цена заказа
		my $order_price = 0;
		for (@{$cart->products->List}) {
			$order_price += $_->{product}{price}
		};

		$order_data->{id_status}   = 1;
		$order_data->{id_net}      = $shop->id_net;
		$order_data->{id_merchant} = $shop->id_merchant;
		$order_data->{price}       = $order_price;
		$order_data->{ctime}       = DateTime->now;

		my $order = ALKO::Order->new($order_data)->Save or return $S->fail("NOSUCH: Can\'t create order");

		for (@{$cart->products->List}) {
			ALKO::Order::Product->new({
				id_order   => $order->id,
				id_product => $_->{product}{id},
				price      => $_->{product}{price},
				qty        => $_->{quantity},
			})->Save;
		};

		$order->products;
		$order->status;
		$order->shop;

		$O->{order} = $order;
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
		allow => ['action', product =>[qw/ id quantity /]],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);
		my $orders = ALKO::Order->All(id_merchant => 47885) or return $S->fail("NOSUCH: no such orders(id_merchant => 47885)");

		for (@{$orders->List}) {
			$_->status;
		}

		$O->{orders} = $orders->List;
		OK;
	},
});

# Добавить товар в корзину
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

		$O->{order} = $order;
		OK;
	},
});


$Server->dispatcher(sub {
	my $S = shift;
	my $I = $S->I;
	return ['ADD']    if exists $I->{action} and $I->{action} eq 'add';
	return ['ORDER']  if exists $I->{action} and $I->{action} eq 'order';
	['LIST'];
});

$Server->listen;