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

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	id_merchant - торговый представитель
 	name        - название корзины
	products    - товары в корзине
=cut
my %Attribute = (
	id_merchant => {mode => undef, type => 'key'},
	name        => {mode => undef},
	products    => {type => 'cache'},
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
	my $picked = ALKO::Cart::Pickedup->Get(id_product => $product->{id}, id_merchant => $self->{id_merchant}, ncart => $self->{n});

 	if ($picked) {
 		# Если товар в корзине уже есть, то прибавляем количество
 		$picked->quantity($picked->quantity + $quantity);
 	} else {
 		# Если такого товара в данной корзине нет, то создаем его
		$picked = ALKO::Cart::Pickedup->new({
			id_merchant => $self->{id_merchant},
			ncart       => $self->{n},
			id_product  => $product->{id},
			quantity    => $quantity,
		});
 	}

 	if (defined $self->{products}) {
		if (my $found = $self->{products}->First_Item(id_product => $product->{id})) {
			$found->quantity($found->quantity + $quantity);
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
	my $picked = ALKO::Cart::Pickedup->Get(id_product => $product->{id}, id_merchant => $self->{id_merchant}, ncart => $self->{n})
		or warn "NOSUCH|WARNING: Can't delete Product from Cart: no such product" , return $self;

 	$picked->Remove;

 	$self;
}

=begin nd
Method: products
	Получить товары в корзине.

Returns:
	$self->{products}
=cut
sub products  {
	my  $self = shift;

	# Если уже есть товары, то ничего не делаем
	return $self->{products} if defined $self->{products};

	# Получаем товары
	my $picked = ALKO::Cart::Pickedup->All(id_merchant => $self->{id_merchant}, ncart => $self->{n});

	# Получаем массив с id товаров
	my @id       = keys %{$picked->Hash('id_product')};
	my $products = ALKO::Catalog::Product->All(id => \@id, SORT =>['name ASC'])->Hash;

	for ($picked->List) {
	    $products->{$_->{id_product}}->price;
		$_->product($products->{$_->{id_product}});
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