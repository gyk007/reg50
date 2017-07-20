package ALKO::Catalog::Property::Matrix::Value;
use base qw/ WooF::Object::Sequence /;

=begin nd
Class: ALKO::Catalog::Property::Matrix::Value
	Набор допустимых значений для каждого измерения каждой матрицы выбора.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	down   - потомок; часть идентификатора измерения
	n_unit - номер измерения; часть идентификатора измерения
	top    - родитель; часть идентификатора измерения
	val    - само значение; одно среди многих (n) значений измерения
=cut
my %Attribute = (
	down   => undef,
	n_unit => undef,
	top    => undef,
	val    => undef,
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
	Строку 'unitvalue'.
=cut
sub Table { 'unitvalue' }

1;
