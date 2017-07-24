package ALKO::Catalog::Property::Param::Value;
use base qw/ WooF::Object /;

=begin nd
Class: ALKO::Catalog::Property::Param::Value
	Значение параметра типа свойства для конкретного свойства.
	
	В члены класса включен избыточный атрибут id_proptype, однозначно определяемый типом самого свойства,
	служащий для предотвращения добавления значения параметра для несуществующего свойства или для свойства,
	не имеющего соответствующего параметра.
	
	У экземпляра два ключа, свойство и его параметр. Ключи составные.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	id_propgroup - группа свойств; элемент ключа свойства, для параметра которого определяется значение
	id_proptype  - тип свойства; элемент ключа параметра свойства
	n_propgroup  - индекс свойства в группе; элемент ключа свойства, для параметра которого определяется значение
	n_proptype   - индекс свойства в типе свойства; элемент ключа параметра свойства
	value        - фактическое значение параметра конкретного свойства
=cut
my %Attribute = (
	id_propgroup => {extern => 'ALKO::Catalog::Property::Group', key => 'property'},
	id_proptype  => {extern => 'ALKO::Catalog::Property::Type',  key => 'proptype'},
	n_propgroup  => {extern => 'Catalog::Property::Group',       key => 'property'},
	n_proptype   => {extern => 'ALKO::Catalog::Property::Type',  key => 'proptype'},
	value        => {mode => 'read'},
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
	Строку 'paramvalue'.
=cut
sub Table { 'paramvalue' }

1;
