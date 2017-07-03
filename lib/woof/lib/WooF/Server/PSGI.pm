package WooF::Server::PSGI;
use base qw/ WooF::Server Exporter /;

=begin nd
Class: WooF::Server
	Реализация PSGI-интерфейса для приложения. 
=cut

use strict;
use warnings;
no warnings 'experimental';

use 5.014;

use Plack;
use Plack::Request;
use Plack::Builder;
use Encode qw/ decode _utf8_off encode_utf8/;
use JSON;
use Time::Moment;

use WooF::Debug;
use WooF::Error;
use WooF::HTTPRequest::PSGI;
use WooF::Server::Constants;

=begin nd
Variable: $Server
	Пакетная переменная, хранящая экземпляр сервера для доступа к нему извне.

Variable: %Attribute
	Описание членов класса, поскольку являемся потомками <WooF::Object>

	Члены класса:
	responder - Ссылка на функцию responder согласно http://search.cpan.org/~miyagawa/PSGI-1.102/PSGI.pod#Delayed_Response_and_Streaming_Body

=cut
use vars qw/ $Server /;

my %Attribute = (
	responder => undef,
);

=begin nd
Method: Attribute ()
	Доступ к хешу с описанием членов класса.
	Может вызываться и как метод экземпляра, и как метод класса.

Returns:
	ссылку на описание членов класса
=cut
sub Attribute { +{ %{+shift->SUPER::Attribute}, %Attribute } }

=begin nd
Method: _cleanup ()
	Завершающие действия в конце обработки очередного запроса.

	Очищает места временного хранения данных, чтобы те не попадали на следующий цикл.

	Если был получен сигнал на завершение Сервера, сервер убивается.
	В противном случае сбрасывается флаг активности рабочего процесса Сервера.
=cut
sub _cleanup {
	my $self = shift;

	$self->{request}->_cleanup;

	# Очищаем члены класа, специфичные для каждого запроса
	my $attribute = $self->Attribute;
	while (my ($attr, $v) = each %$attribute) {
		unless (exists $v->{stable} and $v->{stable}) {
			if (exists $v->{default}) {
				$self->{$attr} = $v->{default};
			} else {
				undef $self->{$attr};
			}
		}
	}

	$self->SUPER::_cleanup;
}

=begin nd
Method: _flush ( )
	Отдать ответ клиенту.
	
	Переопределяет метод в <WooF::Server> устанавливая процесс вывода в соттветствие
	с соглашением PSGI.
=cut
sub _flush {
	my $self = shift;
	
	$self->{responder}->([
		200,
		[
			'Content-Type' => $self->{output_t} eq 'JSON' ? 'text/json' : 'text/html',
			charset => 'utf8',
		],
		[$self->{content}]
	]);
}

=begin nd
Method: init ($env)
	Инициализация перед обработкой очередного HTTP запроса

Parameters:
	$env - ссылка на хэш с переменными окружения. См. подробности в описании Plack::Request.
=cut
sub init {
	my ($self, $env) = @_;
	
	# Запускаем секундомер как можно раньше
	my $start = Time::Moment->now;

	# Очищаем стек ошибок
	WooF::Error::init();

	$self->{request} = $self->init_httprequest($start, $env);

	$self->{iflow} = {};
	$self->{oflow} = {};
	$self->_parse_cgi;

	$self->{user} = $self->authenticate or return if $self->{auth};

	# Устанавливаем порядок действий
	$self->{workqueue} = defined $self->{dispatcher} ? $self->{dispatcher}->($self) : ['DEFAULT'] or warn 'NO_HANDLER|ERR: No any handle match the request';
}

=begin nd
Method: init_httprequest ($start, $env)
	Создать экземпляр класса, который соответствует обрабатываемому HTTP запросу.

Parameters:
	$start - время начала обработки HTTP запроса
	$env   - хэш с переменными окружения

Returns:
	Экземпляр класса <WooF::HTTPRequest::PSGI>
=cut
sub init_httprequest {
	my ($self, $start, $env) = @_;

	WooF::HTTPRequest::PSGI->new($env, tik => $start);
}

=begin nd
Method: listen ()
	Метод обрабатывающий запросы.
=cut
sub listen {
	my $self = shift;
	
	builder {
		mount '/' => builder {
			sub {
				my $env = shift;

				$self->init($env);
# 				debug 'SERVER_AFTER_Q_INIT', $self; # В $self->{request} есть экземпляр plack

				return sub {
					$self->{responder} = shift;
					if (all_right) {
						HANDLER:
						while (my $name = shift $self->{workqueue}) {
							die "No such Handler: $name" unless exists $self->{handler}{$name};
							# Структура обработчика, полученная из скрипта
							my $handler = $self->{worker} = $self->{handler}{$name};
							# Структура обработчика, полученная из скрипта запускает контроллер ввода
							unless ($handler->in) {
								warn 'INPUT: Input iflow does\'t satisfy rules in handler ', $handler->name;
								$self->{workqueue} = [];
								$handler->cleanup;
								last;
							}

							# Каждый обработчик должен вернуть Код Возврата
							my $rc = $handler->{call}->($self);

							$rc ||= FAIL;
							if ($rc eq OK) {
								debug DL_SRV, "RC of handler $name is ", OK;
							} elsif ($rc eq FAIL) {
								debug DL_SRV, "RC of handler $name is ", FAIL;

								last HANDLER;
							} elsif ($rc eq REDIRECT) {
								debug DL_SRV, "RC of handler $name is ", REDIRECT;

								last HANDLER;
							} elsif ($rc eq WORKFLOW) {
								debug DL_SRV, "RC of handler $name is ", WORKFLOW;
							} else {
								warn "|ERR: Unknown return code: $rc in Handler $name";
								last HANDLER;
							}
							
							$handler->cleanup;
						}
					} else {
						warn "SOMETHING WRONG before main loop\n";
					}
					$self->_output;
# 					debug 'SERVER_AFTER_OUTPUT', $self;# В $self->{request} есть экземпляр plack

					# Необходимо очистить именно здесь, чтобы деструктор сработал сразу по завершении итерации,
					# а не ждал начала следующей, которая будет еще неизвестно когда
					$self->_cleanup;
# 					debug 'SERVER_AFTER_CLEANUP', $self;  # СЮДА код не доходит, потому что нет таблицы httprequest, при этом запрос plack не просит.
				}
			}
		};

		mount "/favicon.ico" => sub {
			my $env = shift;
			open my $fh, "<:raw", "favicon.ico" or warn "No favicon found: $!";
			$fh and return [ 200, ['Content-Type' => 'image/x-icon'], $fh ];
		};
	}
}

=begin nd
Method: _parse_cgi ()
	Помещает в Поток параметры CGI-запроса.
	Формирует в потоке вложенные хеши на основании значения ключа входного параметра.
=cut
sub _parse_cgi {
	my $self = shift;

	my $request = $self->{request};
	my $params = {%{$request->parameters}, $request->uploads ? %{$request->uploads} : ()};
# 	debug 'UPLOADS_IN_PARSE=', $request->uploads;

	for my $name (keys %$params) {
		# Разбиваем имя параметра на отдельные ключи будущих вложенных хешей
		my @keys = split '\.', $name;

		# Последний элемент в имени, которому и будет присвоено значения.
		# Остальные элементы в имени используются только для создания (или прохода) хеша.
		my $last = pop @keys;

		# Рекурсивно проходимся по всем именам параметров, кроме последнего
		my $target = $self->{iflow};
		for (@keys) {
			# если в потоке хеша с таким именем еще нет, создаем его
			exists $target->{$_} && ref $target->{$_} eq 'HASH'
				or
					$target->{$_} = {};

			# Опускаемся вниз, в только что созданный хеш
			$target = $target->{$_};
		}
		$target->{$last} = decode 'utf8', $params->{$name};
	}
}

1;
