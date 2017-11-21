package WooF::Server;
use base qw/ WooF::Object Exporter /;

=begin nd
Class: WooF::Server
	Обычно скрипт является FastCGI-программой, представляющей из себя сервер.
	Данный класс реализует логику работы такого скрипта-сервера.

	Поскольку программа без дополнительных настроек в выше лежащем менеджере процессов работает в бесконечном цикле,
	необходимо закрывать сокеты, с осотрожностью использовать флаг 'o' в регулярных выражениях, помнить о сохранении
	значений переменных в последовательных запросах метода <listen ()>

Example:
(start code)
my $Server = WooF::Server->new;

$Server->add_handler(WORK => {
	page = 'mywork',
	call => sub {
		my $Server = shift;

		return OK;
	},
	input => {
		allow => [param1, param2=>[param21, param22]]
	}
});

$Server->add_handler(STUFF => {
	call => sub {
		my $Server = shift;

		$Server->O->{stuff} = 'foo';

		return OK;
	}
});

$Server->dispatcher(sub {
	my $Server = shift;

	return [ qw/ WORK STUFF / ] if $Server->I->{id};
	return [ qw/ STUFF / ];
});
(end)

Существует вырожденный случай, когда обработчик один.
Если дать ему имя DEFAULT, то можно не устанавливать диспетчер, очередь методов выполнения будет состоять из одного этого обработчика.
=cut

use strict;
use warnings;

use CGI::Fast;
use Encode qw/ decode _utf8_off encode_utf8/;
use XML::LibXML;
use XML::LibXSLT;
use XML::Simple;
use JSON;
use Template;
use Time::Moment;

use WooF::DB;
use WooF::Debug;
use WooF::Error;
use WooF::HTTPRequest::FastCGI;
use WooF::Server::PSGI;
use WooF::Server::Constants;
use WooF::Server::Handler;
use POSIX qw(strftime);

=begin nd
Variable: our @EXPORT
	Экспортируемые по дефолту имена
	- OK
	- FAIL
	- REDIRECT

Variable: our @EXPORT_OK
	Имена, экспортируемые по приказу
	- PAGELESS
=cut
our @EXPORT = qw/ OK FAIL REDIRECT /;
our @EXPORT_OK = qw/ PAGELESS /;

=begin nd
Variable: $Server
	Пакетная переменная, хранящая экземпляр сервера для доступа к нему извне.

Variable: %Attribute
	Описание членов класса, поскольку являемся потомками <WooF::Object>

	Члены класса:
	auth       - Если задан ненулевой атрибут, то для доступа требуется аутентификация пользователя. Для этого необходимо переопределить метод authenticate
	cgi        - Текущий запрос, экземпляр Fast::CGI
	content    - тело ответа клиенту
	cwd        - Current Working Directory, текущая рабочая дира
	db         - Соединение с базой данных, экземпляр <WooF::DB>
	dispatcher - Ссылка на метод определения порядка вызова обработчиков
	iflow      - Поток ввода
	             Биндится в шаблон, поэтому обязательно должен быть обнулен перед очередной итерацией в главном цикле <listen ()>
	             В элемент ERROR потока будут привязаны ошибки, поэтому использовать его для других целей нельзя
	json       - Экземпляр модуля JSON, используемого для вывода сервера в JSON-формате
	handler    - Хеш зарегистрированных обработчиков
	header     - набор заголовков для отдачи клиенту
	redirect   - URI для переадресации, если необходимо произвести
	request    - Экземпляр клиентского запроса
	oflow      - Поток вывода
	output_t   - формат вывода; может принимать значения: 'XSLT', 'JSON', 'TT'
	user       - Объект пользователя
	tt         - Объект Template для обработки шаблонов TPL.
	tt_content - Результат обработки TPL шаблона
	worker     - ссылка на текущий исполняемы хендлер, экземпляр <Woof::Server::Handler>
	workqueue  - Порядок вызова обработчиков, ссылка на массив имен
	xslt       - отпарсенный шаблон

	Описание атрибутов соответствует семантике <WooF::Object>. Дополнительный флаг stable избавляет атрибут от уничтожения в <_cleanup ()>
=cut
use vars qw/ $Server /;

my %Attribute = (
	auth       => {default => 1, stable => 1},
	cgi        => {mode => 'read'},
	content    => undef,
	cwd        => {stable => 1},
	db         => {stable => 1},
	dispatcher => {mode => 'write', stable => 1},
	iflow      => {default => {}},
	json       => {stable => 1},
	handler    => {stable => 1},
	header     => undef,
	redirect   => {mode => 'write'},
	request    => {mode => 'read', stable => 1},
	oflow      => {default => {}},
	output_t   => {default => 'XSLT', stable => 1},  # если дать разрешение на запись, то надо каким-то образом восстанавливать значение на следующей итерации
	user       => undef,
	tt         => {stable => 1},
	tt_content => undef,
	worker     => undef,
	workqueue  => undef,
	xslt       => {stable => 1},
);

=begin nd
Method: Attribute ()
	Доступ к хешу с описанием членов класса.

Returns:
	ссылку на хеш
=cut
sub Attribute { \%Attribute }

=begin nd
Variable: my $Interrupted
	Флаг, говорящий о том, что Сервер хотят остановить (получен сигнал)

Variable: my $AtWork
	флаг, указывающий, выполняет ли сервер код в рабочем цикле listen () или заблокирован в ожидании нового запроса
=cut
my ($Interrupted, $AtWork);

# Делаем все, чтобы мягко заглушить Сервер
$SIG{TERM} = $SIG{INT} = \&interrupt;

=begin nd
Constructor: new ()
	Сохраняет объект сервера в пакетной переменной <$Server>.
=cut
sub new {
	my $class = shift;

	chomp(my $cwd = `pwd`);
# 	warn "CWDIR=$cwd";

	$Server = $class->SUPER::new(
		cwd => $cwd,
		@_,
	);

	$Server->{db} = WooF::DB->new if exists WooF::C->{db};
	$Server = bless $Server, 'WooF::Server::PSGI' if WooF::C->{serverType} eq 'PSGI';

	$Server->{json} = JSON->new->allow_nonref->pretty(1)->allow_blessed->convert_blessed if $Server->{output_t} eq 'JSON';

	$Server;
}

=begin nd
Method: add_handler ($name, \%handler)
	Зарегистрировать обработчик.

	Порядок регистрации обработчиков значения не имеет.

	Обработчики сохраняются в специальном хеше, откуда позже они будут извлечены по имени.

	Если указана страница, то в случае вывода через XML+XSLT, отпарсенный xslt будет сохранен под именем страницы в хеше $self->{xslt}{имя_страницы}.

	Имя обработчика должно быть уникально в пределах одного скрипта (сервера).

Parameters:
	$name - имя обработчика
	\%handler - обработчик представляет из себя ссылку на хеш, содержащий обратный вызов под именем 'call', который будет исполнен в основном рабочем цикле сервера.
	            Обработчик может указать имя страницы вывода, представляющей собой имя файла без расширения. Расширение не указывается для того, чтобы можно было
	            оперативно поменять метод вывода. В этом случае в качестве шаблонов будут файлы с одинаковым базовым именем, но разным расширением.
	            Кроме страницы и функции в хендлер можно включить контроллер ввода, описывающий входные параметры хендлера.
	            См пример в описании класса <WooF::Server>

Returns:
	true  - если обработчик удачно зарегистрирован
	false - в противном случае
=cut
sub add_handler {
	my ($self, $name, $handler) = @_;

	return warn "HANDLER|CRIT: Redefining of handler $name is prohibited" if exists $self->{handler}{$name};

	my $Handler = WooF::Server::Handler->new($handler, name => $name) or return warn "HANDLER|CRIT: Can't initiate handler $name";

	$self->{handler}{$name} = $Handler;
	my $page = $Handler->page || DEFAULT_TEMPLATE;

	unless ($page eq PAGELESS) {
		if ($self->{output_t} eq 'XSLT') {
			$self->_build_xslt($page, "$self->{cwd}/$page" . XSLT_FILE_SUFFIX);
		}
	}
}

=begin nd
Method: authenticate ()
	Метод класса. Производит аутентификацию пользователя.
	По умолчанию отключен (возвращает true).
	Если нужно включить аутентификацию, метод должен быть перезагружен в наследующем классе соответствующим образом.

Returns:
	1 - аутентификация отключена
=cut
sub authenticate {
	1;
}

=begin nd
Method: _build_tt ($page)
	Отпарсить файл шаблона в случае вывода методом TT
	Если шаблон имеет переменные, то подставить в него соответствующие значения из потока.
	Объект Template инициализируется при первом обращении и затем используется при всех последующих вызовах.
	Результат обработки шаблона сохраняется в $self->{tt_content}
=cut
sub _build_tt {
	my $self = shift;

	$self->{tt} = Template->new({
		INCLUDE_PATH => $self->{cwd},
		INTERPOLATE  => 0,
		RELATIVE     => 1,
		ENCODING     => 'utf8',
	}) unless $self->{tt};

	unless ($self->{tt}->process($self->{page} . TT_FILE_SUFFIX, $self->{iflow}, \$self->{tt_content})) {
		my $error = $self->{tt}->error;
		warn '|ERR: Template error: ' . $error->as_string();
	}
}

=begin nd
Method: _buil_xslt ($page, $path)
	Отпарсить файл шаблона в случае вывода методом XML.
=cut
sub _build_xslt {
	my ($self, $page, $path) = @_;
# 	warn "PATHXLS=$path";

	eval {
		$self->{xslt}{$page} = XML::LibXSLT->new->parse_stylesheet_file($path);
	};
	warn "$@$!" if $@;
}

=begin nd
Method: _cleanup ()
	Завершающие действия в конце обработки очередного запроса.

	Очищает места временного хранения данных, чтобы те не попадали на следующий цикл.

	Если был получен сигнал на завершение Сервера, сервер убивается.
	В противном случае сбрасывается флаг активности рабочего процесса Сервера.
=cut
sub _cleanup {
	my $self = shift;

	$self->{request}->tok(Time::Moment->now);

	# Очищаем члены класа, специфичные для каждого запроса
	my $attribute = $self->Attribute;
	while (my ($attr, $v) = each %$attribute) {
		undef $self->{$attr} unless exists $v->{stable} and $v->{stable};
	}

# 	debug 'WOOF_SERVER_CLEANUP=', $self;
	$self->{request}->Save;
# 	debug 'WOOF_SERVER_CLEANUP2=', $self;
	$Interrupted ? die("Server stopped") : undef $AtWork;
}

=begin nd
Method: D ()
	Доступ к экземпляру базы <WooF::DB>, используемому сервером.
=cut
sub D { shift->{db} }

=begin nd
Method: fail ($err)
	Останавливает цепочку, устанавливает сообщение об ошибке.

Parameters:
	$err - сообщение об ошибке
=cut
sub fail {
	my ($self, $err) = @_;

	warn $err;

	FAIL;
}

=begin nd
Method: _flush ( )
	Отдать ответ клиенту.
=cut
sub _flush {
	my $self = shift;

	print $self->{cgi}->header(@{$self->{header}}), Encode::encode_utf8($self->{content});
	debug strftime "%H:%M:%S\n", localtime;
}

=begin nd
Method: handler_fail (@handlers)
	Заменяет существующую рабочую очередь обработчиков на новую.

Parameters:
	@handlers - очередь из новых имен, ранее зарегистрированных обработчиков.

Returns:
	OK

Example:
> $server->handler_fail(qw/ FORM CREATE /);
=cut
sub handler_fail {
	my ($self, @handlers) = @_;

	$self->{workqueue} = [@handlers];

	OK;
}

=begin nd
Method: I ( )
	Метод доступа к потоку ввода

Returns:
	$self->{iflow}
=cut
sub I { shift->{iflow} }

=begin nd
Method: init ()
	Иницализация основного цикла при получении очередного HTTP запроса на обработку
=cut
sub init {
	my $self = shift;

	# Запускаем секундомер как можно раньше
	my $start = Time::Moment->now;

	# Начиная с этого места убивать в произвольном месте сервер - нехорошо
	$AtWork = 1;

	# Очищаем стек ошибок
	WooF::Error::init();

	# Заводим экземпляр клиентского запроса
	# это надо сделать до аутентификации, иначе не будет работать tok, так как не будет создан экземпляр запроса, которому он принадлежит
	$self->{request} = $self->init_httprequest($start);

	# Парсить входной поток надо до вызова диспетчера, так как диспетчер оперирует входными параметрами
	$self->{iflow} = {};
	$self->_parse_cgi;

	# Аутентификация
	if ($self->{auth}) {
		$self->{user} = $self->authenticate or return warn 'AUTH: Authentication failed';
	}

	# Устанавливаем порядок действий
	$self->{workqueue} = defined $self->{dispatcher} ? $self->{dispatcher}->($self) : ['DEFAULT'] or warn 'NO_HANDLER|ERR: No any handle match the request';


	# Дефолтная страница шаблона
	$self->{page} = DEFAULT_TEMPLATE;
}

=begin nd
Method: init_httprequest ($start)
	Создать экземпляр класса, который соответствует обрабатываемому HTTP запросу.

Parameters:
	$start - время начала обработки HTTP запроса

Returns:
	Экземпляр класса <WooF::HTTPRequest::FastCGI>
=cut
sub init_httprequest {
	my ($self, $start) = @_;

	WooF::HTTPRequest::FastCGI->new(tik => $start)
}

=begin nd
Function: interrupt ($signal)
	Функция, вызываемая при перехвате сигналов на остановку Сервера.

	Перехватываются сигналы TERM и INT.

	TERM посылается апачем при 'apachectl graceful'

Parameters:
	$signal - строка с кодом сигнала
=cut
sub interrupt {
	my $signal = shift;

	warn "The $signal signal received";

	$AtWork ? $Interrupted = 1 : die "Server stoped";
};

=begin nd
Method: listen ()
	Главный цикл, обрабатывающий запросы.

Returns:
	бесконечный цикл, не возвращается.
=cut
sub listen {
	my $self = shift;

	while ($self->{cgi} = CGI::Fast->new) {
		$self->init;

		if (all_right) {
			HANDLER:
			while (my $name = shift @{$self->{workqueue}}) {
				die "No such Handler: $name" unless exists $self->{handler}{$name};

				# Структура обработчика, полученная из скрипта запускает контроллер ввода
				my $handler = $self->{worker} = $self->{handler}{$name};

				unless ($handler->in) {
					warn 'INPUT: Input iflow does\'t satisfy rules in handler ', $handler->name;
					$self->{workqueue} = [];
					$handler->cleanup;
					last;
				}

				# Каждый обработчик должен вернуть Код Возврата
				my $rc = $handler->call->($self);

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
			warn "|ERR: Error in main loop";
		}

		$self->_output;

		# Необходимо очистить именно здесь, чтобы деструктор сработал сразу по завершении итерации,
		# а не ждал начала следующей, которая будет еще неизвестно когда
		$self->_cleanup;
	}
}

=begin nd
Method: O ( )
	Метод доступа к потоку вывода

Returns:
	$self->{oflow}
=cut
sub O { shift->{oflow} }

=begin nd
Method: _output ( )
	Вывод результатов работы скрипта.
=cut
sub _output {
	my $self = shift;

	if ($self->{redirect}) {
		print $self->{cgi}->redirect(
			-uri    => $self->{redirect},
			-status => 303,
		);
		return;
	}

	# Биндим в поток ошибки со стека и из сессии
	WooF::Error::bind $self->{oflow}{ERROR};

	$self->{header} = [
		-type => 'text/html; charset=utf-8',
	];

	if ($self->{output_t} eq 'XSLT') {
		my $xml_source = XMLout($self->{oflow});
		debug DL_SRV, "xml_source=", $xml_source;
		my $xml_parser = XML::LibXML->new;
		my $xml = $xml_parser->load_xml(string => $xml_source);

		my $page = $self->{worker}->page || DEFAULT_TEMPLATE;
		my $xslt = $self->{xslt}{$page};
		my $result = $self->{xslt}{$page}->transform($xml);
		$self->{content} = qq{<!DOCTYPE html>\n} . $xslt->output_as_bytes($result);
	} elsif ($self->{output_t} eq 'JSON'){
		$self->{content} = $self->{json}->utf8->encode($self->{oflow});
	} elsif ($self->{output_t} eq 'TT') {
		$self->_build_tt;
		$self->{content} = $self->{tt_content};
	}

	$self->_flush;
}

=begin nd
Method: _parse_cgi ()
	Помещает в Поток параметры CGI-запроса.
	Формирует в потоке вложенные хеши на оснавании значения ключа входного параметра.
=cut
sub _parse_cgi {
	my $self = shift;

	for my $name ($self->{cgi}->param) {
		# Разбиваем имя параметра на отельные ключи будущих вложенных хешей
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
		$target->{$last} = decode 'utf8', $self->{cgi}->param($name);
	}
}

=begin nd
Method: U ()
	Метод доступа к пользователю

Returns:
	$self->{user}
=cut
sub U { shift->{user} }

1;
