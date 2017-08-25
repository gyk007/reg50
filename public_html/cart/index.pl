#! /usr/bin/perl
#
# Работа с корзиной.
#

use strict;
use warnings;

use ALKO::Server;
use ALKO::Cart;
use ALKO::Catalog::Product;
use ALKO::Client::Shop;
use ALKO::Client::Net;

my $Server = ALKO::Server->new(output_t => 'JSON', auth => 1);

# Добавить товар в корзину
#
# POST
# URL: /cart/?
#   action           = add
#   product.id       = 20
#   product.quantity = 2
#
$Server->add_handler(ADD => {
	input => {
		allow => ['action', product =>[qw/ id quantity /]],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $cart = ALKO::Cart->Get(id_shop => $O->{SHOP}{id}, n => 1)  or return $S->fail('OBJECT: Can\'t add Product to Cart: no such cart(id_shop => $O->{SHOP}{id}, n => 1)');

		my $product = ALKO::Catalog::Product->Get(id => $I->{product}{id})  or return $S->fail("OBJECT: Can\'t add Product to Cart: no such product($I->{product}{id})");

		$cart->add_product($product, $I->{product}{quantity})->products;

		$O->{cart} = $cart;

		OK;
	},
});

# Получить корзину
# URL: /cart/
$Server->add_handler(CART => {
	input => {
		allow => [],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $cart = ALKO::Cart->Get(id_shop => $O->{SHOP}{id}, n => 1) or return $S->fail('OBJECT: Can\'t get Cart: no such cart(id_shop => $O->{SHOP}{id}, n => 1)');

		$cart->products;
		$O->{cart} = $cart;

		OK;
	},
});

# Удалить товар из корзины
#
# URL: /cart/?
#   action     = delete
#   product.id = 20
#
$Server->add_handler(DELETE => {
	input => {
		allow => ['action', product =>[qw/ id /]],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $cart = ALKO::Cart->Get(id_shop => $O->{SHOP}{id}, n => 1) or return $S->fail('OBJECT: Can\'t delete Product from Cart: no such cart(id_shop => $O->{SHOP}{id}, n => 1)');

		my $product = ALKO::Catalog::Product->Get(id => $I->{product}{id})  or return $S->fail("OBJECT: Can\'t delete Product from Cart: no such product($I->{product}{id})");

		$cart->delete_product($product)->products;

		$O->{cart} = $cart;

		OK;
	},
});

$Server->dispatcher(sub {
	my $S = shift;
	my $I = $S->I;
	return ['ADD']    if exists $I->{action} and $I->{action} eq 'add';
	return ['DELETE'] if exists $I->{action} and $I->{action} eq 'delete';

	['CART'];
});

$Server->listen;