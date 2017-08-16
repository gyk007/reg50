package ALKO::Client::Official;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Client::Official
	Реквизиты.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

Члены класса:
	id_file       - логотип
	name          - название компании
	person        - директор
	address       - фактический адрес
	regaddress    - юридический адрес
	phone         - телефон
	email         - адрес электронной почты
	bank          - наименование банка
	account       - номер расчетного счета
	bank_account  - номер корреспондентского счета
	bik           - БИК
	taxcode       - ИНН
	taxreasoncode - КПП
	regcode       - ОГРН
	alkoid        - ид в системе заказчика
=cut
my %Attribute = (
	id_file       => {mode => undef, type => 'key'},
	name          => {mode => undef},
	person        => {mode => undef},
	address       => {mode => undef},
	regaddress    => {mode => undef},
	phone         => {mode => undef},
	email         => {mode => undef},
	bank          => {mode => undef},
	account       => {mode => undef},
	bank_account  => {mode => undef},
	bik           => {mode => undef},
	taxcode       => {mode => undef},
	taxreasoncode => {mode => undef},
	regcode       => {mode => undef},
	alkoid        => {mode => undef},
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
	Строку 'Official'.
=cut
sub Table { 'Official' }

1;