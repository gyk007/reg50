package ALKO::Catalog::Property::Value;
use base qw/ WooF::Object /;

=begin nd
Class: ALKO::Catalog::Property::Value
	Значение свойства товара.
	
	Значения бывают разных типов, поэтому они разнесены по атрибутам, соответствующих типу значения.
	Тип значения свойств хранится в <ALKO::Catalog::Property::Type>.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	id_product   - каждый товар имеет собственное значение для каждого свойства
	id_propgroup - группа свойств, как часть определения свойства
	n_property   - порядковый номер свойства в группе, как часть определения свойства
	val_bool     - логическое
	val_char     - строка
	val_float    - вещественное число
	val_int      - целое число
	val_time     - дата/время
=cut
my %Attribute = (
	id_product   => undef,
	id_propgroup => undef,
	n_property   => undef,
	val_bool     => undef,
	val_char     => undef,
	val_float    => undef,
	val_int      => undef,
	val_time     => undef,
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
	Строку 'propval'.
=cut
sub Table { 'propval' }

1;
