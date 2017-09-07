package ALKO::Catalog::Property::Type::Engine;
use base qw/ WooF::Object /;

=begin nd
Class: ALKO::Catalog::Property::Type::Engine
	Базовый класс движков все типов свойств.
	
	Подключает классы всех имеющихся движков.
=cut

use strict;
use warnings;

use WooF::Error;

use ALKO::Catalog::Property::Param;
use ALKO::Catalog::Property::Param::Value;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	propgroup - id группы свойств; часть ключа, определящего свойство
	propn     - n; индекс свойства в группе; часть ключа, определяющего свойство
	store     - хранимое значение
=cut
my %Attribute = (
	property => undef,
	store     => {mode => 'write'},
	store_t   => {mode => 'read', default => 'integer'},
);

=begin nd
Method: Attribute ( )
	Доступ к хешу с описанием членов класса.

	Может вызываться и как метод экземпляра, и как метод класса.

Returns:
	ссылку на описание членов класса
=cut
sub Attribute { \%Attribute }

=begin nd
	Виртуальный рабочий метод типа.
	
	Каждый класс-потомок самостоятельно определяет логику обработки и формат возврата значения пользователю.
	
	Если код поднялся до этого места, значит произошла ошибка.
	
Returns:
	undef
=cut
sub operate {
	my $self = shift;
	my $class = ref $self;
	
	warn "CATALOG: Method operate must be redefined in class $class";
}

=begin nd
Method: param ($name)
	Получить значение параметра типа свойства для конкретного свойства по имени параметра.
	
Returns:
	значение параметра - если значение существует
	undef - если произошла ошибка
=cut
sub param {
	my ($self, $name) = @_;

	my $src_param = ALKO::Catalog::Property::Param->Get(id_proptype => $self->{property}->id_proptype, name => $name) or return warn "OBJECT: Property Engine can't operate: param failure";
	
	my $src_val = ALKO::Catalog::Property::Param::Value->Get(
		id_propgroup => $self->{property}->id_propgroup,
		n_propgroup  => $self->{property}->n,
		n_proptype   => $src_param->n,
	) or return warn "OBJECT: Property Engine can't operate: parameter value failure";
	
	my $src = $src_val->value;
}

=begin nd
Method: want  
	Виртуальные метод.

Returns:
	пустой массив
=cut
sub want {[]}
