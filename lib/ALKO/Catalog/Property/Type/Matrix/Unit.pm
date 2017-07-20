package ALKO::Catalog::Property::Matrix::Unit;
use base qw/ WooF::Object::Sequence /;

=begin nd
Class: ALKO::Catalog::Property::Matrix::Unit
	Измерения матрицы выбора.
	
	У каждой ноды есть матрица выбора, задающая соответствие между совокупностью
	значений собвственных параметров и следующей нодой в дереве.
	Каждый параметр называется "измерением матрицы".
	
	Параметры матрицы пронумерованы, поэтому данный класс является потомком <WooF::Object::Sequence>.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	description - описание
	down        - потомок; часть идентификатора ноды матрицы
	name        - имя параметра
	top         - родитель; часть идентификатора ноды матрицы
=cut
my %Attribute = (
	description => undef,
	down        => undef,
	name        => undef,
	top         => undef,
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
	Строку 'matrixunit'.
=cut
sub Table { 'matrixunit' }

1;
