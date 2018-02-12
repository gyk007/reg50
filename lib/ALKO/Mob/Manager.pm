package ALKO::Mob::Manager;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Mod::Manager
	Менеджер (торговый представитель).
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	password - пароль
	email    - почтовй адрес
	name     - имя
	phone    - телефон
	firebase - токен firebase
=cut
my %Attribute = (
	password => {mode => 'read/write'},
	email    => {mode => 'read/write'},
	name     => {mode => 'read/write'},
	phone    => {mode => 'read/write'},
	firebase => {mode => 'read/write'}
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
	Строку 'mob_manager'.
=cut
sub Table { 'mob_manager' }

1;