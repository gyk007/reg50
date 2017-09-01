package ALKO::Client::Merchant;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Client::Merchant
	Представитель.
=cut

use strict;
use warnings;
use WooF::Debug;
use ALKO::Client::Net;
use ALKO::Client::Shop;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	alkoid   - ид в системе заказчика
	email    - адрес электроной почты
	name     - имя
	password - пароль
	phone    - телефон
	net      - организация, экземпляр класса <ALKO::Client::Net>
	net      - список торговых точек, экземпляры класса <ALKO::Client::Shop>
=cut
my %Attribute = (
	alkoid   => {mode => 'read/write'},
	email    => {mode => 'read/write'},
	name     => {mode => 'read/write'},
	password => {mode => 'read/write'},
	phone    => {mode => 'read/write'},
	net      => {mode => 'read', type => 'cache'},
	shops    => {mode => 'read', type => 'cache'},
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
Method: net
	Получить данные о сети.

Returns:
	$self->{net}
=cut
sub net {
	my $self = shift;
	# Если уже есть данные, то ничего не делаем
	return $self->{net} if defined $self->{net};

	my $net =  ALKO::Client::Net->Get(id_merchant => $self->{id});
	$net->official;

	$self->{net} = $net;
}

=begin nd
Method: net
	Получить данные о торговых точках.

Returns:
	$self->{shops}
=cut
sub shops {
	my $self = shift;
	# Если уже есть данные, то ничего не делаем
	return $self->{shops} if defined $self->{shops};

	my $net = $self->{net};

	unless ($net) {
		$net =  ALKO::Client::Net->Get(id_merchant => $self->{id});
	}

	my $shops =  ALKO::Client::Shop->All(id_net => $net->id)->List;

	for(@$shops) {
		$_->official;
	}

	$self->{shops} = $shops;
}

=begin nd
Method: Table ( )
	Таблица хранения сущности в базе данных.

Returns:
	Строку 'merchant'.
=cut
sub Table { 'merchant' }

1;