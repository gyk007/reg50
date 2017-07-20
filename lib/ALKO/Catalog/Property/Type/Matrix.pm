package ALKO::Catalog::Property::Matrix;
use base qw/ WooF::Object::Sequence /;

=begin nd
Class: ALKO::Catalog::Property::Matrix
	Ноды матрицы.
	
	Матрица выбора состоит из нод. Все ноды пронумерованы в произвольном порядке внутри своей матрицы.
	
	Не все возможные ноды матрицы выбора должны быть определены.
	Могут существовать такие комбинации значений параметров выбора,
	для которых нет прохода вниз по дереву типов свойств.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	down     - потомок; часть идентификатора матрицы
	nextdown - потомок в дереве типов, на который осуществляется проход через данную ноду
	top      - родитель; часть идентификатора матрицы
=cut
my %Attribute = (
	down     => undef,
	nextdown => undef,
	top      => undef,
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
	Строку 'matrix'.
=cut
sub Table { 'matrix' }

1;
