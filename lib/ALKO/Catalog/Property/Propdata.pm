package ALKO::Catalog::Property::Data;
use base qw/ WooF::Object /;

=begin nd
Class: ALKO::Catalog::Property::Data
	идентификационные строки для свойсв.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	id_propgroup - группа свойсв
	n_property   - номер группы в свойстве
	extra        - идентификационная строка
	description  - описание
=cut
my %Attribute = (
	id_propgroup => {type => 'key'},
	n_property   => {type => 'key'},
	extra        => {type => 'key'},
	description  => undef,
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
Method: Table ( )
	Таблица хранения сущности в базе данных.

Returns:
	Строку 'propdata'.
=cut
sub Table { 'propdata' }

1;