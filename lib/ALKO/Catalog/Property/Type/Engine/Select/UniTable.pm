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

# Получаем идентификационное значение для свойсва "Made In"
my $extra_country = ALKO::Catalog::Property::Data->Get(extra => 'made_in');

=begin nd
Method: operate ($data)
	Вычислить name по хранимому id из указанной таблицы.
Parameters:
	$table_prop - ссылка на хэш ($table_prop->{название класса для свойсва}{ид свойсва в таблице} = значение из таблицы)

Returns:
	строку из name - в случае отсутствия ошибок
	undef          - если при вычислении возникли ошибки
=cut
sub operate {
	my ($self, $table_prop) = @_;
	debug $table_prop;
	my $src = $self->param('source');

	my $module = $src;
	$module =~ s!::!/!g;
	$module .= '.pm';
	require $module or return warn "OBJECT: Can'n load module $module";

	my $value;
	if($table_prop) {
		$value = $table_prop->{1}{$src}{$self->{store}};
	} else {
		my $obj = $src->Get($self->{store}) or return warn "NOSUCH|WARNING: Can't get value for property";
		$value  = $obj->name;
	}

	$value;
}

1;
