package ALKO::Mod::News::Manager;
use base qw/ WooF::Object /;

=begin nd
Class: ALKO::Mod::Manager
	Менеджер (торговый представитель).
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	id_mob_news    - id новости
	id_mob_manager - id менеджера 
=cut
my %Attribute = (
	id_mob_news    => {mode => 'read/write', type => 'key'}
    id_mob_manager => {mode => 'read/write', type => 'key'}	 
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
	Строку 'mob_news_manager'.
=cut
sub Table { 'mob_news_manager' }

1;