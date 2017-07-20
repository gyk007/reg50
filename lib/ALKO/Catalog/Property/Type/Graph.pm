package ALKO::Catalog::Property::Type::Graph;
use base qw/ WooF::Object /;

=begin nd
Class: ALKO::Catalog::Property::Type::Graph
	Дерево типов свойств товара.
	
	Направленный граф. Сиблинги не имеют сортировки за ненадобностью.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	down - потомок
	top  - родитель
=cut
my %Attribute = (
	down => undef,
	top  => undef,
);

=begin nd
Method: Attribute ( )
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
	Строку 'proptype_graph'.
=cut
sub Table { 'proptype_graph' }

1;
