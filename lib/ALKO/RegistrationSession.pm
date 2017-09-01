package ALKO::RegistrationSession;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::RegistrationSession
	Cессия для регистрации.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
    token       - токен
    id_merchant - представитель,
    ctime       - время создагия сессии,
    dtime       - время конца срока дейсвия сессии,
    count       - количесво посещений по текущей сессии,
=cut
my %Attribute = (
	token       => undef,
	id_merchant => {mode => 'read'},
	ctime       => undef,
	dtime       => {mode => 'read'},
	count       => {mode => 'read'},
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
	Строку 'reg_session'.
=cut
sub Table { 'reg_session' }