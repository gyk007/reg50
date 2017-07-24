package ALKO::Catalog::Property::Type;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Catalog::Property::Type
	Тип свойства товара.
	
	Любое свойство товара имеет конкретный тип. Тип свойства определяет
	тип значений, которые могут в нем храниться, и от него зависит
	алгоритм получения значения возвращаемого пользователю, формат его вывода.
	
	Каждому типу соответствуют движок в ALKO::Catalog::Property::Type::Engine::*.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	name        - наименование на русском используется для выбора типа при добавлении нового свойства
	description - полное описание назначения типа
	class       - класс поддержки ALKO::Catalog::Property::Type::*
=cut
my %Attribute = (
	name        => undef,
	description => undef,
	class       => {mode => 'read'},
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
	Строку 'proptype'.
=cut
sub Table { 'proptype' }

1;
