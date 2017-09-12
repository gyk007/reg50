package ALKO::Client::Net;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Client::Net
	Сеть магазинов.
=cut

use strict;
use warnings;

use ALKO::Client::Official;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	id_official - реквизиты
	id_merchant - представитель
	official    - реквизиты, экземпляр класса <ALKO::Client::Official>
	merchant    - представитель сети экземпляр класса <ALKO::Client::Merchant>
=cut
my %Attribute = (
	id_official => undef,
	id_merchant => {mode => 'read'},
	official    => {mode => 'read', type => 'cache'},
	merchant    => {mode => 'read', type => 'cache'},
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
Parameters:
	$official  - экземпляр класса <ALKO::Client::Official>

Returns:
	$self->{official}
=cut
sub official {
	my ($self,  $official)  = @_;
	# Если уже есть данные, то ничего не делаем
	return $self->{official} if defined $self->{official};

	if ($official) {
		$self->{official} = $official;
	} else {
		$self->{official} = ALKO::Client::Official->Get(id => $self->{id_official});
	}

	$self->{official};
}

=begin nd
Method: merchant
	Получить данные о merchant.
Parameters:
	$merchant  - экземпляр класса <ALKO::Client::Merchant>

Returns:
	$self->{merchant}
=cut
sub merchant {
	my ($self,  $merchant)  = @_;
	# Если уже есть данные, то ничего не делаем
	return $self->{merchant} if defined $self->{merchant};

	if ($merchant) {
		$self->{merchant} = $merchant;
	} else {
		$self->{merchant} = ALKO::Client::Merchant->Get(id => $self->{id_merchant});
	}

	$self->{merchant};
}

=begin nd
Method: Table ( )
	Таблица хранения сущности в базе данных.

Returns:
	Строку 'net'.
=cut
sub Table { 'net' }

1;