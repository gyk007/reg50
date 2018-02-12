package ALKO::File;
$VERSION = 0.1;

=nd
Package: ALKO::Files
	Класс для работы с файлами
=cut
use strict;
use warnings;
use WooF::Debug;
use File::Copy qw(move);

=nd
Constructor: new ($port, $host)
	Конструктор
Parameters:
	$param           - ссылка на хэш
	$param->{path}   - путь сохранения файла
	$param->{upload} - объект Plack::Request::Upload
	$param->{name}   - новое имя файла
=cut
sub new {
	my ($class, $param) = @_;
	my $self = bless {
		path   => $param->{path},
		upload => $param->{upload},
		name   => $param->{name}
	}, $class;
}

=nd
Method: upload_file
	Загрузка файла на сервер
=cut
sub upload_file {
	my $self = shift;
	my $file_name = $self->{upload}{filename};
	my $path      = $self->{path};
	# Получаем расширение файла
	my ($file_extension) = $file_name =~ m#([^.]+)$#;
	$file_extension =~ /\.([^.]+)$/gi;
	$file_extension = lc $file_extension;
	# Создаем каталог если его не существует
	mkdir $path if (!-d $path);
	# Новое имя если задано в параметрах
	$file_name = $self->{name}.'.'.$file_extension if $self->{name};
	# Путь с именем файла
	$path .= $file_name;
	# Перемещаем файл
	move $self->{upload}{tempname}, $path;

	return $file_name;
}

1;