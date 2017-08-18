#! /usr/bin/perl
#
# Работа с заказами.
#

use strict;
use warnings;
use WooF::Debug;
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
#
$Server->add_handler(ADD => {
	input => {
		allow => [
			'action',
			order => [qw/ phone address name remark email id_shop /],
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

		$order_data->{id_status}   = 1;
		$order_data->{id_net}      = $shop->id_net;
		$order_data->{id_merchant} = $shop->id_merchant;

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
		$order->net;
		debug $order;
		$O->{order} = $order;
		OK;
	},
});

$Server->add_handler(ORDER => {
	input => {
		allow => ['action', product =>[qw/ id quantity /]],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		OK;
	},
});


$Server->dispatcher(sub {
	my $S = shift;
	my $I = $S->I;
	return ['ADD']    if exists $I->{action} and $I->{action} eq 'add';


	['ORDER'];
});

$Server->listen;