package WooF::HTTPRequest::PSGI;
use base qw / WooF::HTTPRequest /;

=begin nd
Class: WooF::HTTPRequest::PSGI
	Клиентский запрос, пришедший через Plack::Request и наделённый соответствующими методами.

	Помимо доступа к структуре HTTP-запроса класс предоставляет такие данные, как
	временные отметки о начале и завершении обработки.
	Архив клиентских запросов сохраняется в таблице httprequest.
=cut

use 5.014;

use strict;
use warnings;
no if $] >= 5.018, warnings => 'experimental';

use Plack::Request;
use WooF::DateTime;

=begin nd
Variable: my %Attribute
	Члены класса:
	plack   - Plack запрос
=cut
my %Attribute = (
	plack   => undef,
);

=begin nd
Method: Attribute ()
	Доступ к хешу с описанием членов класса.

Returns:
	Ссылку на хеш.
=cut
sub Attribute { +{ %{+shift->SUPER::Attribute}, %Attribute } }

=begin nd
Constructor: new ($env)
	Конструктор создаёт экземпляр Plack::Request и использует его для разбора поступившего HTTP запроса.

Parameters:
	$env - ссылка на хэш, описывающий окружение с полной информацией об обрабатываемом запросе.

Returns:
	экземпляр клиентского запроса.
=cut
sub new {
	my ($class, $env) = (shift, shift);

	my $plack = Plack::Request->new($env);
	my $param = $plack->parameters->as_hashref;

	$class->SUPER::new(
		headers => $plack->headers->as_string,
		ip      => $plack->address,
		method  => $plack->method,
		path    => $plack->path_info,
		qstring => join('&', map "$_=$param->{$_}", keys $param),
		referer => $plack->headers->header('Referer') || undef,
		plack   => $plack,
		@_,
	);
}

=begin nd
Method: _cleanup ()
	Завершающие действия в конце обработки очередного запроса.

	Фиксирует время завершения обработки. Готовит материалы для записи в таблице HTTPRequest.
=cut
sub _cleanup {
	my $self = shift;

	$self->tok(WooF::DateTime->new->timestamp);
	undef $self->{plack};
}

=begin nd
Method: new_response ()
	Доступ к методу new_response экземпляра Plack::Request

Returns:
	Ссылку на хеш.
=cut
sub new_response {
	my $self = shift;

	$self->{plack}->new_response(@_);
}

=begin nd
Method: parameters ()
	Доступ к методу parameters экземпляра Plack::Request

Returns:
	Ссылку на хеш.
=cut
sub parameters {
	my $self = shift;

	$self->{plack}->parameters;
}

=begin nd
Method: uploads ()
	Доступ к методу uploads экземпляра Plack::Request

Returns:
	Ссылку на хеш.
=cut
sub uploads {
	my $self = shift;

	$self->{plack}->uploads;
}

1;
