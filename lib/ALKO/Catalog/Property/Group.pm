package ALKO::Catalog::Property::Group;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Catalog::Property::Group
	Группа свойств товаров.
	
	Группа является контейнером для набора свойств.
	Каждое свойство принадлежит только одной конкретной группе.
	
	Группа может быть одновременно привяязана к нескольким категориям.
	Группы наследуются вниз по дереву категорий. Группа, вложенная в такую же группу верхнего уровня, переопределяет ее.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	description - полное описание
	face        - наименование, выводимое в каталоге
	name        - наименование
	visible     - видимость свойства и всех его значений в каталоге для покупателя
=cut
my %Attribute = (
	description => undef,
	face        => undef,
	name        => undef,
	visible     => undef,
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
sub Table { 'propgroup' }

1;
