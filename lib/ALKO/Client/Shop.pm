package ALKO::Client::Shop;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Client::Shop
	Магазин.
=cut

use strict;
use warnings;

use ALKO::Client::Official;
use ALKO::Client::Net;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	id_merchant - представитель
	id_net      - сеть
	id_official - реквизиты
=cut
my %Attribute = (
	id_merchant => {mode => 'read', type => 'key'},
	id_net      => {mode => 'read', type => 'key'},
	id_official => {mode => undef,  type => 'key'},
	official    => {mode => 'read', type => 'cache'},
	net         => {mode => 'read', type => 'cache'},
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
Method: official
	Получить данные о магазине.

Returns:
	$self->{official}
=cut
sub official {
	my $self = shift;
	$self->{official} = ALKO::Client::Official->Get(id => $self->{id_official});
}

=begin nd
Method: net
	Получить данные о сети.

Returns:
	$self->{net}
=cut
sub net {
	my $self = shift;
	my $net =  ALKO::Client::Net->Get(id => $self->{id_net});
	$net->official;
	$self->{net} = $net;
}

=begin nd
Method: Table ( )
	Таблица хранения сущности в базе данных.

Returns:
	Строку 'shop'.
=cut
sub Table { 'shop' }

1;