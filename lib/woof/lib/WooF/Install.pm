package WooF::Install;
use base qw / WooF /;

=begin nd
Class: WooF::Install
	Генерирование конфигурационного файла Apache и запуск скриптов создающих структуру базы данных.

Example:
(start code)
#! /usr/bin/perl

use strict;
use warnings;

use WooF::Install;

my $install = WooF::Install->new(__FILE__);

$install->generate_fcgi_config('init.conf');

$install->complete;
(end)
=cut

use strict;
use warnings;

use IO::File;
use Pg::CLI::psql;

=begin nd
Constants:
	FCGI_TPL_PATH      - Часть пути к шаблонам конфигов для mod_fcgi относительно корня скриптов веб-сервера (/home/puplin/project/webserver/install)
	FCGI_CONF_PATH     - Часть пути к свежесгенерированному конфигу
	SQL_PATH           - Часть пути до директории с sql-скриптами
	STEPSDONE_FILENAME - Имя файла, содержащего имена выполненных инсталляторов
=cut
use constant {
	FCGI_TPL_PATH  => '/fcgi',
	FCGI_CONF_PATH => '/conf/fcgid.conf.example',
	SQL_PATH       => '/sql',
	STEPSDONE_PATH => '/steps.completed',
};

=begin nd
Constructor: new ($stepname)
	Запоминаем номер степа.
	
Parameters:
	$stepname - имя файла степа
	
Returns:
	Экземпляр.
=cut
sub new {
	my ($class, $stepname) = @_;
	
	$stepname =~ s!^.*/!!;
	return unless $stepname;

	bless {
		stepname => $stepname,
	}, $class;
}

=begin nd
Method: complete ($message)
	Завершение работы инсталлятора.
	В случае удачного исполнения всех действий в steps.completed дописывается имя инсталляционного файла.

Parameters:
	$message - сообщение, выводимое по окончании работы скрипта.

	Если после удачной отработки скрипта требуются дополнительные действия со стороны админа,
	то есть смысл поместить их описание именно сюда.

Example:
(start code)
$install->complete(<<"EOF");
1. Replace Apache's config file now!
...
N. Upgrade Database.
EOF
(end code)
=cut
sub complete {
	my ($self, $message) = @_;

	my $path = $self->C->{install} . STEPSDONE_PATH;
	
	my $completed = IO::File->new(">> $path") or die "Can't open special 'steps.completed' file '$path': $!";
	print $completed "$self->{stepname}\n";
	close $completed or die "Can't close special 'steps.completed' file $path: $!";

	binmode STDOUT, ":utf8";
	print $message || "Done\n";
}

=begin nd
Method: generate_fcgi_config ($tpl)
	Генерирование конфигурационного файла fcgid.conf

Parameters:
	$file_name - имя шаблона. Находится в webserv/install/fcgi
=cut
sub generate_fcgi_config {
	my ($self, $tpl) = @_;

	die "FCGID template config isn't specified" unless defined $tpl and $tpl =~ /^\w+\.conf$/;
	
	my $C = $self->C;
	
	my $src_path = $C->{install} . FCGI_TPL_PATH . "/$tpl";
	my $dst_path = $C->{apache}  . FCGI_CONF_PATH;
	
	my $src = IO::File->new("< $src_path") or die "Can't open Apache config template file $src_path: $!";
	binmode $src, ":utf8";

	my $dst  = IO::File->new("> $dst_path") or die "Can't open Apache FCGI example config file $dst_path: $!";
	binmode $dst, ":utf8";

	while (<$src>) {
		s/\@{2}APACHEROOT\@{2}/$C->{apache}/g;
		s/\@{2}WEBSERV\@{2}/$C->{webserv}/g;
		s/\@{2}WOOF_CONFIG\@{2}/$ENV{WOOF_CONFIG}/g;

		# Найти пути к библиотекам в блоке $C->{lib}
		# и выполнить их подстановку по примеру $line =~ s/\@{2}WOOFLIB\@{2}/$C->{lib}{woof}/g;
		while (my($k, $v) = each %{$C->{lib}}) {
			my $k = uc($k) . 'LIB';
			s/\@{2}$k\@{2}/$v/g;
		}

		print $dst $_;
	}

	close $src or die "Can't close Apache config template file $src_path: $!";
	close $dst or die "Can't close Apache FCGI example config file $dst_path: $!";
} 

=begin nd
Method: sql ($filename)
	Выполнить SQL-команды из файла с указанным именем.
	Имя файла должно иметь формат name.sql
	Файл ищется в папке $self->C->{install} . SQL 
=cut
sub sql {
	my ($self, $filename) = @_;

	die 'No sql filename specified' unless defined $filename and $filename =~ /^\w+\.sql$/;

	my $C = $self->C;

	die "It's not allowed to alter tables with that script. Check the <sql_master> tag in global.xml." unless $C->{sql_master};

	my $dbconf = $C->{db};
	my $statement_file = $C->{install} . SQL_PATH . "/$filename";
	
	my $fh = IO::File->new("< $statement_file") or die "Can't open SQL file $statement_file: $!";
	my $statement;
	while (<$fh>) {
		s/\@{2}DBUSER\@{2}/$dbconf->{role}{user}{login}/go;
		$statement .= $_;
	}

	$fh->close or die "Can not close SQL file: $!";

	my $psql = Pg::CLI::psql->new(
		username => $dbconf->{role}{admin}{login},
		password => $dbconf->{role}{admin}{password},
		host     => $dbconf->{location}{host},
		port     => $dbconf->{location}{port},
	);

	my $errors;
	my $s = $psql->run(
		database => $dbconf->{name},
		stdin    => \$statement,
		stderr   => \$errors
	);

	die "Can not execute:\n$statement \n $errors" if $errors =~ /ERROR:/;
}

1;
