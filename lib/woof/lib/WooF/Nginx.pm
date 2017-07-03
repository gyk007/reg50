package WooF::Nginx;

=begin nd
Class: WooF::Nginx
	Сохранение и удаление файлов на файл-сервере с помощью протокола DAV 
=cut

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request;
use XML::Hash;

use WooF;
use WooF::Debug;

=begin nd
Constructor: new ()
	Получает экземпляр класса, содержащий всю информацию для подключения к файл-серверу DAV.

=cut
sub new {
	my $class = shift;

	my $conf = WooF::C->{dav};

	my $user_agent = new LWP::UserAgent;
	$user_agent->credentials($conf->{host}, 'DAV', $conf->{login}, $conf->{password});

	my $self = {
		ua  => $user_agent,
		url => $conf->{url},
	};

	bless $self, $class;

	return $self;
}

=begin nd
Method: delete ($uri)
	Удалить указанный файл на файл-сервере.

Parameters:
	$uri - адрес URI удаляемого файла

Returns:
	1     - в случае успеха
	undef - если возникли какие-либо проблемы
=cut
sub delete {
	my ($self, $uri) = @_;

	my $request = HTTP::Request->new();
	$request->method('DELETE');
	$request->uri($self->{'url'} . '/' . $uri);

	my $response = $self->{'ua'}->request($request);

	unless ($response->is_success)
	{
# Не сообщаем об ошибке 404, поскольку метод PROPFIND отключен и
# мы не можем проверить, существует ли файл, который мы собираемся удалять
#		debug DL_SRV, "METHOD:DELETE URI:$uri Status:" . $response->status_line;
		return undef;
	}

	1;
}

=begin nd
Method: put ($uri, $filename)
	Поместить указанный файл на файл-сервер.

Parameters:
	$uri      - адрес URI удаляемого файла
	$filename - путь к закачиваемому файлу в локальной файловой системе (абсолютный или относительный)

Returns:
	1     - в случае успеха
	undef - если возникли какие-либо проблемы
=cut
sub put {
	my ($self, $uri, $filename) = @_;

	my $request = HTTP::Request->new();
	$request->method('PUT');
	$request->uri($self->{'url'} . '/' . $uri);

	my $fsize = -s $filename;
	$request->header('Content-length' => $fsize);

	my ($content, $fh);

	open($fh, '<:raw', $filename) or do
	{
		debug DL_SRV, "Can't open file $filename for reading";
		return;
	};
	binmode($fh);
	read($fh, $content, $fsize);

	$request->content($content);

	my $response = $self->{'ua'}->request($request);

	unless ($response->is_success)
	{
		debug DL_SRV, "METHOD:PUT URI:$uri Status:" . $response->status_line;
		return;
	}

	1;
}

1;
