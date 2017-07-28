package ALKO::Catalog::Filter::Arg::PropLink;
use base qw/ WooF::Object /;

=begin nd
Class: ALKO::Catalog::Filter::Arg::PropLink
	Состав аргументов для фильтра каждого свойства.
	
	Нас не интересует порядок следования аргументов.
=cut

use strict;
use warnings;

=begin nd
Variable: my %Attribute
	Члены класса:
	filterarg    - экземпляр <ALKO::Catalog::Filter::Arg>, соответствующий значению в id_filterarg
	id_filterarg - один из конкретных аргументов фильтра указанного Свойства
	id_propgroup - группа свойств от ключа Свойства
	n_property   - номер свойства в группе от ключа Свойства
=cut
my %Attribute = (
	filterarg    => {mode => 'read/write', type => 'cache'},
	id_filterarg => {mode => 'read'},
	id_propgroup => {mode => 'read'},
	n_property   => undef,
);

=begin nd
Method: Attribute ( )
	Доступ к хешу с описанием членов класса.
	
	Может вызываться и как метод экземпляра, и как метод класса.

Returns:
	ссылку на описание членов класса
=cut
sub Attribute { \%Attribute }

sub Table { 'filterarg_link' }

1;
