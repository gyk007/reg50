package ALKO::Client::File;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Client::File
	Файлы клиента (организации).
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	path    - путь к файлу
	name    - название файла
	ext     - расширение
	size    - размер файла
	taxcode - ИНН организации (у некоторых организаций одинаковый ИНН , поэтому связь по ИНН)
=cut
my %Attribute = (
	path    => undef,
	name    => undef,
	ext     => undef,
	size    => undef,
	taxcode => undef,
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
	Строку 'file'.
=cut
sub Table { 'file' }

1;