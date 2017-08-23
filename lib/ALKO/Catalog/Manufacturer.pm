package ALKO::Catalog::Manufacturer;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Catalog::Manufacturer
	Производитель товара.

	Производитель может владеть несколькими брендами <ALKO::Catalog::Brand>.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	alkoid      - идентификатор во внешней системе
	description - полное описание
	name        - наименование
=cut
my %Attribute = (
	alkoid      => undef,
	description => undef,
	name        => {mode => 'read'},
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
	Строку 'manufacturer'.
=cut
sub Table { 'manufacturer' }

1;
