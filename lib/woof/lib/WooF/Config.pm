package WooF::Config;

=begin nd
Class: WooF::Config
	Конфигурационные данные веб-части. Доступ через <WooF::C ()>
	Главный хеш со всеми конфигурационными параметрами получается в результате
	обработки основного файла конфигурации проекта.

	Читаем глобальный XML-конфиг, проверяем схему. В случае ошибки пишем в апачевский лог и умираем.

	Вычисленный хеш конфига сохраняется в пакетной переменной <$DATA>.
=cut

use strict;
use warnings;

use XML::Simple;
use XML::LibXML;

=begin nd
Constant: CONF_PATH
	Путь к каталогу, где находятся файлы конфигурации проекта.
	Берётся из переменной окружения WOOF_CONFIG.

Constant: CONFIG_FILE
	Имя основного файла конфигурации проекта.

Constant: SCHEMA_FILE
	Имя файла со схемой, которой должен с файл конфигурации проекта.
=cut
use constant {
	CONF_PATH => $ENV{WOOF_CONFIG} || "$ENV{HOME}/.woof",
	CONFIG_FILE => 'global.xml',
	SCHEMA_FILE => 'global.xsd',
};

=begin nd
Variable: $DATA
	Главный хеш.
	Ссылка на хеш с конфигурационными параметрами, полученными из основного конфигурационного файла.

See <WooF::C>
=cut
use vars qw/ $DATA /;

my $conf_path = CONF_PATH . '/' . CONFIG_FILE;
-e $conf_path or die "No main config '$conf_path' file found.";

# Разбор файла 
my $xml = XML::LibXML->new->parse_file($conf_path);  

# Файл схемы должен находиться там же, где и файл конфига
my $schema = XML::LibXML::Schema->new(location => CONF_PATH . '/' . SCHEMA_FILE);

# Если ошибка, то перехватываем её, чтобы далее вывести в stderr и завершить работу
eval {$schema->validate($xml)};

if ($@) {
	print STDERR "File global.xml does not match a given schema. Error message: $@\n";
	exit;
}

$DATA = XMLin($conf_path, ForceArray=>0);

1;
