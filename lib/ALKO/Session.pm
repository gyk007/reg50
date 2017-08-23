package ALKO::Session;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Session
	Cессия.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
    coockie     - куки
    id_merchant - представитель,
    ctime       - время создагия сессии,
    ltime       - время последнего визита представителя,
=cut
my %Attribute = (
	coockie     => undef,
	id_merchant => undef,
	ctime       => undef,
	ltime       => undef,
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
	Строку 'orders'.
=cut
sub Table { 'session' }