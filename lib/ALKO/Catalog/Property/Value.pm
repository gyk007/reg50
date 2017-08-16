package ALKO::Catalog::Property::Value;
use base qw/ WooF::Object /;

=begin nd
Class: ALKO::Catalog::Property::Value
	Значение свойства товара.

	Набор свойств для всех товаров в одной группе одинаков, но значения свойств для каждого товара свое.

	Занчения бывают двух видов: "хранимые" и "вычисленные".
	Хранимые значения сохранены в таблице и используются для вычисления второго вида. Данный класс реализует
	"хранимые" значения.

	Значения бывают разных типов, поэтому они разнесены по различным атрибутам таблицы класса, соответствующих типу значения.
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
	id_product   => {mode => 'read', type => 'key'},
	id_propgroup => {mode => 'read', type => 'key'},
	n_property   => {mode => 'read', type => 'key'},
	val_bool     => undef,
	val_char     => undef,
	val_float    => {mode => 'read'},
	val_int      => {mode => 'read'},
	val_time     => undef,
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
	Строку 'propval'.
=cut
sub Table { 'propvalue' }

1;
