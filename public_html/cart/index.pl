#! /usr/bin/perl
#
# Работа с корзиной.
#

use strict;
use warnings;

use ALKO::Server;
use ALKO::Cart;
use ALKO::Catalog::Product;
use ALKO::Cart::Pickedup;
use ALKO::Client::Shop;
use ALKO::Client::Net;

use WooF::Debug;

my $Server = ALKO::Server->new(output_t => 'JSON', auth => 1);

=begin nd
Constant: MAX_QTY_IN_CART
	Максимальное количесво товара в корзине
=cut
use constant {
	MAX_QTY_IN_CART => 9999,
	MIN_QTY_IN_CART => 1,
};

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

		# Нельзя добавить больше чем MAX_QTY_IN_CART
		$I->{product}{quantity} = MAX_QTY_IN_CART if $I->{product}{quantity} >= MAX_QTY_IN_CART;
		# Нельзя добавить меньше чем MIN_QTY_IN_CART
		$I->{product}{quantity} = MIN_QTY_IN_CART if $I->{product}{quantity} <= MIN_QTY_IN_CART;

		my $cart = ALKO::Cart->Get(id_shop => $O->{SESSION}->id_shop, n => 1)  or return $S->fail('OBJECT: Can\'t add Product to Cart: no such cart(id_shop => $O->{SHOP}{id}, n => 1)');

		my $product = ALKO::Catalog::Product->Get(id => $I->{product}{id})  or return $S->fail("OBJECT: Can\'t add Product to Cart: no such product($I->{product}{id})");

		$cart->add_product($product, $I->{product}{quantity})->products($O->{SESSION}->id_shop);

		$O->{cart} = $cart;

		OK;
	},
});

# Добавить количесво к товару в корзине
#
# POST
# URL: /cart/?
#   action           = add_qty
#   product.id       = 20
#   product.quantity = 2
#
$Server->add_handler(ADD_QTY => {
	input => {
		allow => ['action', product =>[qw/ id quantity /]],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		# Нельзя добавить больше чем MAX_QTY_IN_CART
		$I->{product}{quantity} = MAX_QTY_IN_CART if $I->{product}{quantity} >= MAX_QTY_IN_CART;
		# Нельзя добавить меньше чем MIN_QTY_IN_CART
		$I->{product}{quantity} = MIN_QTY_IN_CART if $I->{product}{quantity} <= MIN_QTY_IN_CART;

		my $cart = ALKO::Cart->Get(id_shop => $O->{SESSION}->id_shop, n => 1)  or return $S->fail('OBJECT: Can\'t add Product to Cart: no such cart(id_shop => $O->{SHOP}{id}, n => 1)');

		my $product = ALKO::Catalog::Product->Get(id => $I->{product}{id})  or return $S->fail("OBJECT: Can\'t add Product to Cart: no such product($I->{product}{id})");

		my $prod_in_cart = ALKO::Cart::Pickedup->Get(id_shop => $O->{SESSION}->id_shop, id_product => $I->{product}{id}) or return $S->fail("OBJECT: Can\'t add Product to Cart: no such product in cart($I->{product}{id})");

		# Меняем количесво продукта в корзине
		$prod_in_cart->quantity($I->{product}{quantity});
		$prod_in_cart->Save;

		$cart->products($O->{SESSION}->id_shop);

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

		my $cart = ALKO::Cart->Get(id_shop => $O->{SESSION}->id_shop, n => 1) or return $S->fail('OBJECT: Can\'t get Cart: no such cart(id_shop => $O->{SHOP}{id}, n => 1)');

		$cart->products($O->{SESSION}->id_shop);
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

		my $cart = ALKO::Cart->Get(id_shop => $O->{SESSION}->id_shop, n => 1) or return $S->fail('OBJECT: Can\'t delete Product from Cart: no such cart(id_shop => $O->{SHOP}{id}, n => 1)');

		my $product = ALKO::Catalog::Product->Get(id => $I->{product}{id})  or return $S->fail("OBJECT: Can\'t delete Product from Cart: no such product($I->{product}{id})");

		$cart->delete_product($product)->products($O->{SESSION}->id_shop);

		$O->{cart} = $cart;

		OK;
	},
});

$Server->dispatcher(sub {
	my $S = shift;
	my $I = $S->I;
	return ['ADD']     if exists $I->{action} and $I->{action} eq 'add';
	return ['ADD_QTY'] if exists $I->{action} and $I->{action} eq 'add_qty';
	return ['DELETE']  if exists $I->{action} and $I->{action} eq 'delete';

	['CART'];
});

$Server->listen;