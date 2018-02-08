package ALKO::News::Merchant;
use base qw/ WooF::Object /;

=begin nd
Class: ALKO::News::Merchant
	Связь пердставитель - новость.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	id_news     - новость
	id_merchant - представитель
=cut
my %Attribute = (
	id_news     => {type => 'key'},
	id_merchant => {type => 'key'},
);

=begin nd
Method: Attribute ( )
	Доступ к хешу с описанием членов класса.

	Может вызываться и как метод экземпляра, и как метод класса.
	Наследует члены класса родителей.

Returns:
	ссылку на описание членов класса
=cut
sub Attribute { \%Attribute }

=begin nd
Method: Table ( )
	Таблица хранения сущности в базе данных.

Returns:
	Строку 'news_merchant'.
=cut
sub Table { 'news_merchant' }

1;