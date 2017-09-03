package ALKO::Statistic::Shop;
use base qw/ WooF::Object /;

=begin nd
Class: ALKO::Statistic::Shop
	Статистика торговых точек.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	id_shop - торговая точка
	name    - название торговой точки
	qty     - количество заказов
	price   - общая стоимость	 
=cut
my %Attribute = (
	id_shop  => {type => 'key'}, 
	name     => undef,
	qty      => {mode => 'read/write'},
	price    => {mode => 'read/write'},	 
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
	Строку 'stat_shop'.
=cut
sub Table { 'stat_shop' }

1;