package ALKO::Catalog::Property;
use base qw/ WooF::Object::Sequence /;

=begin nd
Class: ALKO::Catalog::Property
	Cвойство товара.
	
	Свойство однозначно принадлежит одной группе свойств <ALKO::Catalog::Property::Group> и имеет индекс
	внутри группы, начинающийся с единицы.
	
	Свойство обладает типом свойства <ALKO::Catalog::Property::Type>, определяющим его поведение.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	const        - короткое имя для постоянных свойств типа "цены", "производителя"; для обращения из кода
	description  - полное описание
	face         - имя для вывода переопределяет name
	filterarg    - коллекция аргументов, необходимых для работы фильтра
	filters      - флаг включающий вывод фильтра для свойства, если фильтр указан в id_filterui
	filterui     - фильтр, экземлляр <ALKO::Catalg::Filter::UI>
	id_filterui  - виджет представления фильтра на клиенте
	id_propgroup - свойство однозначно принадлежит Группе Свойств <ALKO::Catalog::Property::Group>
	               и занимает свое место, определяемое индексом последовательности 'n'
	id_proptype  - свойство имеет определенный тип
	name         - имя для админки и, если не переопределено, то и для юзера
	value        - значение свойства конкретного товара
	visible      - выводить ли свойство в каталог
=cut
my %Attribute = (
	const        => undef,
	description  => undef,
	face         => undef,
	filterarg    => {mode => 'read/write', type => 'cache'},
	filters      => {mode => 'read',},
	filterui     => {mode => 'write', type => 'cache'},
	id_filterui  => {mode => 'read', extern => 'ALKO::Catalog::Filter::UI'},
	id_propgroup => {mode => 'read'},
	id_proptype  => {mode => 'read'},
	name         => undef,
	value        => {mode => 'read/write', type => 'cache'},
	visible      => undef,
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
Method: Table ( )
	Таблица хранения сущности в базе данных.

Returns:
	Строку 'property'.
=cut
sub Table { 'property' }

1;
