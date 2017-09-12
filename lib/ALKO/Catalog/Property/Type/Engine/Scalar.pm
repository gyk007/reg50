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
Method: operate (store_t)
	Получить вычисленное значение.

	Вычисленное значение равно хранимому. Вычислений не требуется.
=cut
sub operate {
	my ($self, $store_t) = @_;

	$self->{store_t} = $store_t ? $store_t : $self->param('store');

	$self->{store};
}

1;
