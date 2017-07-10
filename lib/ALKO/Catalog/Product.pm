package ALKO::Catalog::Product;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Catalog::Product
	Товар как единица презентации в каталоге, в противовес единице поставки.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	description    - полное описание
	face           - наименование, выводимое в каталоге
	face_effective - наименование в каталоге, переопределенное категорией
	name           - наименование
	properties     - значения свойств; разбиты по группам
	visible        - видимость товара в каталоге для покупателя
=cut
my %Attribute = (
	description    => undef,
	face           => undef,
	face_effective => {type => 'cache'},
	name           => undef,
	properties     => {mode => 'read/write', type => 'cache'},
	visible        => undef,
);

=begin nd
Method: Attribute ()
	Доступ к хешу с описанием членов класса.
	
	Может вызываться и как метод экземпляра, и как метод класса.
	Наследует члены класса родителей.

Returns:
	ссылку на описание членов класса
=cut
sub Attribute { +{ %{+shift->SUPER::Attribute}, %Attribute} }

=begin nd
Method: Table ( )
	Таблица хранения сущности в базе данных.

Returns:
	Строку 'category'.
=cut
sub Table { 'product' }

1;
