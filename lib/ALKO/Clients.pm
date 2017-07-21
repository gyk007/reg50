package ALKO::Clients;
use base qw/ WooF::Object /;

=begin nd
Class: ALKO::Clients
	Список клиентов.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	id             - id
	name           - название магазина
	representative - имя представителя
	address        - адрес магазина
	phone          - телефон магазина
	mail           - майл магазина
	visible        - выводить ли клиента в списке
=cut
my %Attribute = (
	id             => {key => 'default', mode => 'read'},
	name           => {mode => 'read/write'},
	representative => {mode => 'read/write'},
	address        => {mode => 'read/write'},
	phone          => {mode => 'read/write'},
	mail           => {mode => 'read/write'},
	visible        => {mode => 'read/write'},
);

=begin nd
Method: Attribute ( )
	Доступ к хешу с описанием членов класса.

	Может вызываться и как метод экземпляра, и как метод класса.
	Наследует члены класса родителей.

Returns:
	ссылку на описание членов класса
=cut
sub Attribute { \%Attribute }

=begin nd
Method: Table ( )
	Таблица хранения сущности в базе данных.

Returns:
	Строку 'clients'.
=cut
sub Table { 'clients' }

1;