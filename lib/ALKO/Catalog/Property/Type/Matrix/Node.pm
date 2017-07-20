package ALKO::Catalog::Property::Matrix::Node;
use base qw/ WooF::Object::Sequence /;

=begin nd
Class: ALKO::Catalog::Property::Matrix::Node
	Определение ноды матрицы значениями ее измерений.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	down    - потомок; часть идентификатора ноды матрицы
	n_unit  - номер измерения матрицы
	n_value - номер значения в списке значений измерения матрицы
	top     - родитель; часть идентификатора ноды матрицы
=cut
my %Attribute = (
	down    => undef,
	n_unit  => undef,
	n_value => undef,
	top     => undef,
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
	Строку 'matrixnode'.
=cut
sub Table { 'matrixnode' }

1;
