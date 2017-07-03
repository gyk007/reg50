package ALKO::Catalog::Property::Type;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Catalog::Property::Type
	Тип свойства товара.
	
	Любое свойство товара имеет конкретный тип. Тип свойства определяет
	тип значения, которое может в нем храниться, и от него зависит
	алгоритм получения значения, и формат вывода значения пользователю.
	
	Только самые простые типы свойств возможно добавить через данный класс,
	так как реализация типа, как правило, требует поддержки в коде.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	name        - наименование на русском используется для выбора типа при добавлении нового свойства
	description - полное описание назначения типа
	valtype     - тип значения хранимого в данном типе свойства; соответствует одноименному атрибуту в <ALKO::Catalog::Property::Value>
=cut
my %Attribute = (
	name        => undef,
	description => undef,
	valtype     => undef,
);

=begin nd
Method: Attribute ()
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
