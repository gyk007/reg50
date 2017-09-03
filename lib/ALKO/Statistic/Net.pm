package ALKO::Statistic::Net;
use base qw/ WooF::Object /;

=begin nd
Class: ALKO::Statistic::Net
	Статистика сетей.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	id_net - сеть
	name   - имя сети
	qty    - количество заказов
	price  - общая стоимость	 
=cut
my %Attribute = (
	id_net  => {type => 'key'}, 
	name    => undef,
	qty     => {mode => 'read/write'},
	price   => {mode => 'read/write'},	 
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
	Строку 'stat_net'.
=cut
sub Table { 'stat_net' }

1;