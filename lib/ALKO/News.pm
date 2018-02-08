package ALKO::Order;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Order
	Заказ.
=cut

use strict;
use warnings;

use ALKO::Client::Net;
use ALKO::Client::Shop;
use ALKO::Order::Document;
use ALKO::Order::Product;
use ALKO::Order::Status;


=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	title - загаловок
	text  - тело новости
	ctime - дата создания
=cut
my %Attribute = (
	title => {mode => 'read/write'},
	text  => {mode => 'read/write'},
	ctime => {mode => 'read/write'},
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
	Строку 'news'.
=cut
sub Table { 'news' }