package ALKO::Cart;
use base qw/ WooF::Object::Sequence /;

=begin nd
Class: ALKO::Cart
	Корзина.

	У торгового представителя может быть несколько корзин.
	Номер корзины укзазан в атрибуте n.
=cut

use strict;
use warnings;

use ALKO::Cart::Pickedup;
use ALKO::Catalog::Product;
use ALKO::Catalog::Property;
use ALKO::Catalog::Property::Value;

use WooF::Debug;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	id_shop  - торговая точка
 	name     - название корзины
	products - товары, список экземпляров класса <ALKO::Catalog::Product>
=cut
my %Attribute = (
	id_shop  => {type => 'key'},
	name     => undef,
	products => {type => 'cache'},
);

=begin nd
Method: Attribute ( )
	Доступ к хешу с описанием членов класса.

	Может вызываться и как метод экземпляра, и как метод класса.
	Наследует члены класса родителей.

Returns:
	ссылку на описание членов класса
=cut
sub Attribute { +{ %{+shift->SUPER::Attribute}, %Attribute} }

=begin nd
Method: add_product ($product, $quantity)
	Добавить товар в корзину.

Parameters:
	$product  - товар, экземпляр клаccа <ALKO::Catalog::Product>
	$quantity - количество

Returns:
	$self
=cut
sub add_product {
	my ($self, $product, $quantity) = @_;

	# Получаем товар в корзине
	my $picked = ALKO::Cart::Pickedup->Get(id_product => $product->{id}, id_shop => $self->{id_shop}, ncart => $self->{n});

 	if ($picked) {
 		# Если товар в корзине уже есть, то прибавляем количество
 		$picked->quantity($quantity);
 	} else {
 		# Если такого товара в данной корзине нет, то создаем его
		$picked = ALKO::Cart::Pickedup->new({
			id_shop     => $self->{id_shop},
			ncart       => $self->{n},
			id_product  => $product->{id},
			quantity    => $quantity,
		});
 	}

 	if (defined $self->{products}) {
		if (my $found = $self->{products}->First_Item(id_product => $product->{id})) {
			$found->quantity($quantity);
		} else {
			$self->{products}->Push($picked);
		}
	}

 	$self;
}

=begin nd
Method: delete_product ($product)
	Удалить товар из корзины.

Parameters:
	$product  - товар, экземпляр клаccа <ALKO::Catalog::Product>

Returns:
	$self
=cut
sub delete_product {
	my  ($self, $product) = @_;

	# Получаем товар
	my $picked = ALKO::Cart::Pickedup->Get(id_product => $product->{id}, id_shop => $self->{id_shop}, ncart => $self->{n})
		or warn "NOSUCH|WARNING: Can't delete Product from Cart: no such product" , return $self;

 	$picked->Remove;

 	$self;
}

=begin nd
Method: products
	Получить товары в корзине.

Parameters:
	$id_shop  - id торговой точки
Returns:
	$self->{products}
=cut
sub products  {
	my  ($self, $id_shop) = @_;

	# Если уже есть товары, то ничего не делаем
	return $self->{products} if defined $self->{products};

	# Получаем товары
	my $picked = ALKO::Cart::Pickedup->All(id_shop => $self->{id_shop}, ncart => $self->{n}, SORT => ['n']);

	# Получаем массив с id товаров
	my @id        = keys %{$picked->Hash('id_product')};
	my $products  = ALKO::Catalog::Product->All(id => \@id, SORT =>['name ASC'])->Hash;

	# Необходимые свойсва для корзины
	my $props       = ALKO::Catalog::Property->All(name => ['Litr', 'Pack'])->Hash('name');
	my $prop_values = ALKO::Catalog::Property::Value->All(id_product => \@id)->Hash('id_product');

	for my $pick ($picked->List) {
		# Получаем свойства и их значения для данного товара
		my $litr;
		my $pack;
		for (@{$prop_values->{$pick->{id_product}}}) {
			$litr = $_->val_float if $_->n_property == $props->{Litr}[0]->n;
			$pack = $_->val_int   if $_->n_property == $props->{Pack}[0]->n;
		}

		my $prop = {
			Litr => $litr,
			Pack => $pack,
		};

	    $products->{$pick->{id_product}}->price($id_shop);
	    $products->{$pick->{id_product}}->properties($prop);

		$pick->product($products->{$pick->{id_product}});
	}

	$self->{products} = $picked;
}

=begin nd
Method: Table ( )
	Таблица хранения сущности в базе данных.

Returns:
	Строку 'cart'.
=cut
sub Table { 'cart' }