package WooF::HTTPRequest::FastCGI;
use base qw / WooF::HTTPRequest /;

=begin nd
Class: WooF::HTTPRequest::FastCGI
	Клиентский запрос, пришедший через CGI.

	Помимо доступа к структуре HTTP-запроса включает наши собственные данные.
	Характерные для обработки любого запроса на обслуживание данные, такие как начальная
	и конечные временные отметки обработки, наследуются от родителя <WooF::HTTPRequest>.
=cut

use strict;
use warnings;

=begin nd
Constructor: new ($NO_SYNC, %attr)
	Конструктор разбирает CGI и на его основе устанавливает значения некоторым атрибутам.

Parameters:
	$NOSYNC - обычный для потомков <WooF::Object> необязательный признак привязки к базе
	%attr   - необязательный хеш с устанавливаемыми значениями членам класса

Returns:
	экземпляр клиентского запроса.

Example:
>my $request = WooF::HTTPRequest::FastCGI->new(NO_SYNC, tik=now());
=cut
sub new {
	my $class = shift;
	
	my $cgi = $class->S->cgi;

	# Пакуем заголовки браузера
	my @header = map +("$_:" . $cgi->http($_)), $cgi->http;
	my $headers;
	{
		local $" = "\n";
		$headers = "@header";
	}

	$class->SUPER::new(
		headers    => $headers,
		ip         => $cgi->http('X-Real-IP') || $cgi->remote_addr,
		method     => $cgi->request_method,
		path       => $cgi->url(-absolute=>1),
		qstring    => $cgi->request_method eq 'GET' ? $cgi->query_string : undef,
		referer    => $cgi->referer,
		@_,
	);
}

1;
