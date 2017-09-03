package ALKO::Order::Product;
use base qw/ WooF::Object::Sequence /;

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
	id_product - товар
	qty        - количество
	price      - цены во время заказа
	product    - товар, экземпляр класса <ALKO::Catalog::Product>
=cut
my %Attribute = (
	id_order   => {type => 'key'},
	id_product => {mode => 'read'},
	qty        => {mode => 'read'},
	price      => {mode => 'read'},
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
	# Если уже есть данные, то ничего не делаем
	return $self->{product} if defined $self->{product};

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