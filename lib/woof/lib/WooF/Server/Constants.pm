package WooF::Server::Constants;
use base qw/ Exporter /;

=begin nd
Class: WooF::Server::Constants
	Константы, необходимые серверу.
	
	Используются в <WooF::Server> и некоторых других служебных модулях,
	не относящихся к слою пользователя.
	
	Поскольку константы используются в модулях с перекрестным включением,
	пришлось вынести их в отдельный файл.
	
	Все константы экспортируются по дефолту.
=cut

use strict;
use warnings;

=begin nd
Constant: OK
	обработчик успешно выполнен, продолжается поток обработки запроса.

Constant: FAIL
	в результате выполнения обработчика произошла критическая ошибка.

Constant: REDIRECT
	обработчик требует редиректа; цепочка выполнения обработчиков будет прервана.

Constant: WORKFLOW
	заменена рабоча очередь обработчиков

Constant: PAGELESS
	Специальное имя страницы обработчика, означающее, что у страницы нет вывода; возможен только редирект.

Constant: DEFAULT_TEMPLATE
	Имя файла дефолтного шаблона без суффикса

Constant: XSLT_FILE_SUFFIX
	Суффикс XSL файла
=cut
use constant {
	# Коды возвратов для обработчика
	OK       => 'OK',
	FAIL     => 'FAIL',
	REDIRECT => 'REDIRECT',
	WORKFLOW => 'WORKFLOW',

	# Специальное 'отсутсвующее' имя страницы handler'а
	PAGELESS => 'PAGELESS',

	# шаблоны
	DEFAULT_TEMPLATE => 'index',
	XSLT_FILE_SUFFIX => '.xsl',
	TT_FILE_SUFFIX   => '.tpl',
};

=begin nd
Variable: @EXPORT
	Экспортируемые по дефолту константы:
	- OK
	- FAIL
	- REDIRECT
	- WORKFLOW
	- PAGELESS
	- DEFAULT_TEMPLATE
	- XSLT_FILE_SUFFIX
	- TT_FILE_SUFFIX
=cut
our @EXPORT = qw/ OK FAIL REDIRECT WORKFLOW PAGELESS DEFAULT_TEMPLATE XSLT_FILE_SUFFIX TT_FILE_SUFFIX /;

1;
