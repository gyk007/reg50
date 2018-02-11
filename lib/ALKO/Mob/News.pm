package ALKO::Mob::News;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Mob::News
	Новость.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	title       - загаловок
	text        - тело новости
	ctime       - дата создания
	description - описание
=cut
my %Attribute = (
	title       => {mode => 'read/write'},
	text        => {mode => 'read/write'},
	description => {mode => 'read/write'},
	ctime       => {mode => 'read/write'},
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
	Строку 'mob_news'.
=cut
sub Table { 'mob_news' }