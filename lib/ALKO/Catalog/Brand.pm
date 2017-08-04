package ALKO::Catalog::Brand;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Catalog::Brand
	Бренд. Торговая марка.

	Бренд может принадлежать товару (а может и не принадлежать).
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	description     - полное описание
	id_manufacturer - владелец бренда
	name            - наименование
	alkoid          - идентификатор во внешней системе
=cut
my %Attribute = (
	description     => undef,
	id_manufacturer => undef,
	name            => {mode => 'read'},
	alkoid          => {mode => 'undef'},
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
	Строку 'brand'.
=cut
sub Table { 'brand' }

1;
