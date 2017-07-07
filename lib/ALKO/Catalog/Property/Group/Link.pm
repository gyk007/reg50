package ALKO::Catalog::Property::Group::Link;
use base qw/ WooF::Object /;

=begin nd
Class: ALKO::Catalog::Property::Group::Link
	Распределение групп свойств по категориям.
	
	Одна категория может содержать несколько групп свойств,
	и одна группа может одновременно находиться в нескольких категориях,
	в том числе и в потомках категории, к которой эта группа уже привязана.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	face         - наименование товара, переопределяющее наименования для конкретной категории
	id_category  - категория каталога
	id_propgroup - группа свойств
	joint        - поместить ли группу в виртуальную общую группу категории; группа не обособляется, заголовок не выводится
	visible      - выводить ли группу и все ее свойства пользователю
	weight       - вес сортировки, определяющий положение среди групп в конкретной категории
=cut
my %Attribute = (
	face         => undef,
	id_category  => undef,
	id_propgroup => {mode => 'read'},
	joint        => undef,
	visible      => undef,
	weight       => undef,
);

=begin nd
Method: Attribute ()
	Доступ к хешу с описанием членов класса.
	Может вызываться и как метод экземпляра, и как метод класса.

Returns:
	ссылку на описание членов класса
=cut
sub Attribute { \%Attribute }

=begin nd
Method: Table ( )
	Таблица хранения сущности в базе данных.

Returns:
	Строку 'grouplink'.
=cut
sub Table { 'grouplink' }

1;
