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

=begin nd
Method: operate ( )
	Вычислить name по хранимому id из указанной таблицы.
	
Returns:
	строку из name - в случае отсутствия ошибок
	undef          - если при вычислении возникли ошибки
=cut
sub operate {
	my $self = shift;
	
	my $src = $self->param('source');
	
	my $module = $src;
	$module =~ s!::!/!g;
	$module .= '.pm';
	require $module or return warn "OBJECT: Can'n load module $module";

	my $obj = $src->Get($self->{store}) or return warn "NOSUCH|WARNING: Can't get value for property";
	
	$obj->name;
}

1;
