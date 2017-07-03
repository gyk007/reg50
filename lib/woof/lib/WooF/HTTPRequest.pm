package WooF::HTTPRequest;
use base qw / WooF::Object::Simple /;

=begin nd
Class: WooF::HTTPRequest
	Данные HTTP-запроса
=cut

use strict;
use warnings;

=begin nd
Variable: my %Attribute
	Члены класса:
	headers - заголовки, переданные браузером
	ip      - IP-адрес клиента
	method  - метод, запрошенный клиентом (GET/POST)
	path    - путь как часть урла
	qstring - Query String
	referer - отдельно заголовок REFERER
	tik     - врема начала обработки запроса скриптом
	tok     - время окончания обработки запроса скриптом
=cut
my %Attribute = (
	headers => undef,
	ip      => undef,
	method  => undef,
	path    => undef,
	qstring => undef,
	referer => undef,
	tik     => {mode => 'read/write'},
	tok     => {mode => 'write'},
);

=begin nd
Method: Attribute ()
	Доступ к хешу с описанием членов класса.

Returns:
	Ссылку на хеш.
=cut
sub Attribute { +{ %{+shift->SUPER::Attribute}, %Attribute } }

sub new {
	my $class = shift;

	warn 'OBJECT|ERR: The HTTPRequest class is abstract one. It cannot be instantiated.' if $class eq __PACKAGE__;
	$class->SUPER::new(@_);
}

=begin nd
Method: Table ()
	Таблица хранения сущности в базе данных.

Returns:
	Строку 'httprequest'.
=cut
sub Table { 'httprequest' }

1;
