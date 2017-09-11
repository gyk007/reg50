package ALKO::Catalog::Property::Type::Engine::Select::UniTable;
use base qw/ ALKO::Catalog::Property::Type::Engine /;

=begin nd
Class: ALKO::Catalog::Property::Type::Engine::Select::UniTable
	Единственное значение поля таблицы.

	Хранится ид записи в таблицы, отдается 'name'.
	Если имена полей надо будет переопределить, нужно создать дополнительные параметры типа.
=cut

use strict;
use warnings;

use WooF::Error;
use WooF::Debug;
use ALKO::Catalog::Property::Data;

# Получаем все идентификационные данные
my $propdata = ALKO::Catalog::Property::Data->All(SORT => 'DEFAULT');
# Хэш: $prop_extra = {id_propgroup}{n_prop} = ['made_in', ...];
my $prop_extra;
for ($propdata->List) {
	push @{$prop_extra->{$_->id_propgroup}{$_->n_property}}, $_->extra;
}

=begin nd
Method: operate ($data)
	Вычислить name по хранимому id из указанной таблицы.
Parameters:
	$extra - ссылка на массив с данными

Returns:
	строку из name - в случае отсутствия ошибок
	undef          - если при вычислении возникли ошибки
=cut
sub operate {
	my ($self, $extra) = @_;

	my $src = $self->param('source');

	my $value;
	if($extra) {
		$value = $_->{$self->{store}}->name for @$extra;
	} else {
		my $module = $src;
		$module =~ s!::!/!g;
		$module .= '.pm';
		require $module or return warn "OBJECT: Can'n load module $module";

		my $obj = $src->Get($self->{store}) or return warn "NOSUCH|WARNING: Can't get value for property";
		$value  = $obj->name;
	}

	$value;
}

=begin nd
Method: want ()
	Метод возвращает список идентификационных данных для конретного свойства.
Returns:
	список идентификационных данных
=cut
sub want {
	my $self = shift;

	my $property = $self->{property};

	exists $prop_extra->{$property->id_propgroup} and exists $prop_extra->{$property->id_propgroup}{$property->n} ?
          $prop_extra->{$property->id_propgroup}{$property->n}
    	: [];
}

1;
