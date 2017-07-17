package ALKO::Catalog::Property::Param;
use base qw/ WooF::Object::Sequence /;

=begin nd
Class: ALKO::Catalog::Property::Param
	Параметр типа свойства.
	
	Тип свойства может нуждаться в дополнительных параметрах, определяющих
	особенности его поведения. Например, устанавливать формат вывода, количество
	знаков после запятой, алгоритм получения списка выбора, и т.п..
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	description - полное описание
	id_proptype - тип свойства, дополняемый параметром
	name        - наименование
=cut
my %Attribute = (
	description => undef,
	id_proptype => {key => {extern => 'Catalog::Property::Type'}},
	name        => undef,
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
	Строку 'propparam'.
=cut
sub Table { 'propparam' }

1;
