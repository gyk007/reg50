package ALKO::Order::Product;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Order::Product
	Товар в заказе.
=cut

use strict;
use warnings;

use ALKO::Catalog::Product;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	id_order   - заказ
	id_product - продукт
	price      - цены во время заказа
	qty        - количество
=cut
my %Attribute = (
	id_order   => {mode => undef},
	id_product => {mode => undef},
	price      => {mode => undef},
	qty        => {mode => undef},
	product    => {mode => 'read', type => 'cache'},
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
Method: product
	Получить данные о товаре.

Returns:
	$self->{product}
=cut
sub product  {
	my  $self = shift;
	$self->{product} = ALKO::Catalog::Product->Get(id => $self->{id_product});
}

=begin nd
Method: Table ( )
	Таблица хранения сущности в базе данных.

Returns:
	Строку 'order_product'.
=cut
sub Table { 'order_product' }

1;