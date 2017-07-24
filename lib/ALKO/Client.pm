package ALKO::Client;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Client
	Список клиентов.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	name    - название магазина
	agent   - имя представителя
	address - адрес магазина
	phone   - телефон магазина
	email   - адрес электронной почты
=cut
my %Attribute = (
	name    => {mode => 'read/write'},
	agent   => {mode => 'read/write'},
	address => {mode => 'read/write'},
	phone   => {mode => 'read/write'},
	email   => {mode => 'read/write'},
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
	Строку 'client'.
=cut
sub Table { 'client' }

1;