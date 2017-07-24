package ALKO::Catalog::Property::Type::Engine::Scalar;
use base qw/ ALKO::Catalog::Property::Type::Engine /;

=begin nd
Class: ALKO::Catalog::Property::Type::Engine::Scalar
	Свойство имеющее простое единичное значение, не треующие вычислений.
	
	Типом значения могутт быть целые и вещественные числа. Для открытия остальных, надо добавить
	их в таблицу значений и открыть права на чтение в модуле значений.
=cut

use strict;
use warnings;

=begin nd
Constructor: new (@data)
	Переопределить тип хранимого значения.
	
	По дефолту тип хранимого значения является целым числом. Но данный класс
	в зависимости от параметра типа может хранить и значения иного типа.
	
Returns:
	$self - без ошибок
	undef - если что-то пошло не так
=cut
sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	
	$self->{store_t} = $self->param('store');
	
	$self;
}

=begin nd
Method: operate ( )
	Получить вычисленное значение.
	
	Вычисленное значение равно хранимому. Вычислений не требуется.
=cut
sub operate {
	my $self = shift;
	
	$self->{store};
}

1;
