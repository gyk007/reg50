package ALKO::Client::Offer;
use base qw/ WooF::Object /;

=begin nd
Class: ALKO::Client::Offer
	Индивидуальное предложение.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	id_product - товар
	id_shop    - торговая точка
	type       - тип скидки; percent - скидка в процентах; rub - рублях
	value      - значение скидки
	ctime      - дата создания
=cut
my %Attribute = (
	id_product => {type => 'key'},
	id_shop    => {type => 'key'},
	type       => {mode => 'read'},
	value      => {mode => 'read'},
	ctime      => undef,
);
=begin nd
Method: Attribute ()
	Доступ к хешу с описанием членов класса.
	Может вызываться и как метод экземпляра, и как метод класса.

Returns:
	ссылку на описание членов класса
=cut
sub Attribute { \%Attribute }

=begin nd
Method: Table ( )
	Таблица хранения сущности в базе данных.

Returns:
	Строку 'offer'.
=cut
sub Table { 'offer' }

1;