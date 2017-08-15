package ALKO::Client;
use base qw/ WooF::Object /;

=begin nd
Class: ALKO::Client
	Клиент (магазин или другая сущность)
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	merchant - представитель
	shop     - магазин
	official - реквизиты
	net      - сеть
=cut
my %Attribute = (
	merchant => {type => 'cache'},
	shop     => {type => 'cache'},
	official => {type => 'cache'},
	net      => {type => 'cache'},
);

=begin nd
Method: Attribute ( )
	Доступ к хешу с описанием членов класса.

	Может вызываться и как метод экземпляра, и как метод класса.

Returns:
	ссылку на описание членов класса
=cut
sub Attribute { \%Attribute }

1;