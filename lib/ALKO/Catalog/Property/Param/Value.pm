package ALKO::Catalog::Property::Param::Value;
use base qw/ WooF::Object::Sequence /;

=begin nd
Class: ALKO::Catalog::Property::Param::Value
	Значение параметра типа свойства для конкретного свойства.
	
	В члены класса включен избыточный атрибут id_proptype, однозначно определяемый типом самим свойством, и который
	служит для предотвращения добавления значения параметра для несуществующего свойства или для свойства,
	не имеющего соответствующего параметра.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	id_propgroup - группа свойств; элемент ключа свойства, для параметра которого определяется значение
	id_proptype  - тип свойства
	n_propgroup  - индекс свойства в группе; элемент ключа свойства, для параметра которого определяется значение
	value        - фактическое значение параметра конкретного свойства
=cut
my %Attribute = (
	id_propgroup => {extern => 'ALKO::Catalog::Property::Group', key => 'property'},
	id_proptype  => {extern => 'ALKO::Catalog::Property::Type'},
	n_propgroup  => {extern => 'Catalog::Property::Group', key => 'property'},
	value        => undef,
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
	Строку 'paramvalue'.
=cut
sub Table { 'paramvalue' }

1;
