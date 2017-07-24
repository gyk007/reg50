package ALKO::Country;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Country
	Страна.
	
	Может быть использована как справочник где-угодно.
	
	Сейчас используется для свойства товара "Страна-производитель".
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	name - наименование
=cut
my %Attribute = (
	name => {mode => 'read'},
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
	Строку 'country'.
=cut
sub Table { 'country' }

1;
