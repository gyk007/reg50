package ALKO::Mob::Tag::News;
use base qw/ WooF::Object /;

=begin nd
Class: ALKO::Mob::Tag::News
	Связь тега и новости
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	id_mob_news     - id новости
	id_mob_news_tag - id тега
=cut
my %Attribute = (
	id_mob_news     => {mode => 'read/write', type => 'key'},
	id_mob_news_tag => {mode => 'read/write', type => 'key'},
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
	Строку 'mob_news_teg_ref'.
=cut
sub Table { 'mob_news_teg_ref' }

1;