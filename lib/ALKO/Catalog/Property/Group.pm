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
	description    - полное описание
	face           - наименование, выводимое в каталоге
	face_effective - наименование в каталоге, переопределенное для категории
	joint          - встраивание группы в "общую" группу свойств категории; устанавливается категорией
	name           - наименование
	properties     - коллекция свойств, входящих в группу
	visible        - видимость группы, ее свойств и всех значений в каталоге для покупателя; устанавливается категорией
	weight         - вес сортировки внутри товара; больше вес, ниже приоритет; устанавливается категорией
=cut
my %Attribute = (
	description    => undef,
	face           => undef,
	face_effective => {type => 'cache'},
	joint          => {mode => 'read/write', type => 'cache'},
	name           => undef,
	properties     => {
	                      mode   => 'read/write',
	                      type   => 'cache',
	                      extern => 'ALKO::Catalog::Property',
	                      maps   => {
	                                    type   => 'multi',
	                                    master => 'id',
	                                    slave  => 'id_propgroup',
	                      },
	               },
	visible        => {type=>'cache'},
	weight         => {type => 'cache'},
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
Method: Table ( )
	Таблица хранения сущности в базе данных.

Returns:
	Строку 'category'.
=cut
sub Table { 'propgroup' }

1;
