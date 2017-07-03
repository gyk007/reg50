package WooF::File;
use base qw / WooF::Object::Simple /;

=begin nd
Class: WooF::File
	Файл, который сохранён на локальном диске сервера или на DAV сервере
=cut

use v5.12.0;

use strict;
use warnings;
no warnings 'experimental::smartmatch';

use File::Basename;
use File::Copy qw(copy);
use File::Temp qw/ tempfile /;  # filename()
use Image::Magick;

use WooF::Error;
use WooF::Nginx;

=begin nd
Variable: my %Attribute
	Члены класса:
	filename - имя файла (например, 'photo.jpg')
	path     - путь к файлу (абсолютный или относительно корня проекта webserv)
=cut
my %Attribute = (
	filename => {mode => 'read'},
	path     => undef,
);

=begin nd
Method: Attribute ()
	Доступ к хешу с описанием членов класса.
	Может вызываться и как метод экземпляра, и как метод класса.

Returns:
	Ссылку на хеш.
=cut
sub Attribute { +{ %{+shift->SUPER::Attribute}, %Attribute } }

=begin nd
Method: Remove ()
	Удаление экземпляра WooF::File со стиранием соответствующего файла.
=cut
sub Remove {
	my $self = shift;

	my $filename = $self->{filename};
	$self->remove($filename);

	$self->SUPER::Remove;
}

=begin nd
Method: remove ($filename)
	Удаление файла из файловой системы или с DAV сервера.

Parameters:
	$filename - имя удаляемого файла
=cut
sub remove {
	my ($self, $filename) = @_;

	given ($self->C->{fileTransport}) {
		when ('LOCAL') {
			unlink $self->C->{archive} . '/' . $filename;
		}
		when ('DAV') {
			my $dav = WooF::Nginx->new;
			$dav->delete($filename);
		}
		default {
			return warn "FILE|ERR: Unknown value in the fileTransport config.";
		}
	}
}

=begin nd
Method: resize_image ($filename, $width, $height)
	Создание копии фотографии, приведенной к заданному размеру.

Parameters:
	$filename - исходный файл, именбшенную копию которого нужно создать
	$width    - максимальная ширина фотографии
	$height   - максимальная высота
=cut
sub resize_image {
	my ($self, $filename, $width, $height) = @_;

	my $new_file = $filename . '_' . $width . 'x' . $height; # выбираем название файла для копии

	my $image = Image::Magick->new;
	return if $image->Read($filename);

	my ($ox, $oy) = $image->Get('base-columns', 'base-rows');
	return unless $ox && $oy;

	$oy *= $width / $ox;
	$ox = $width;
	if ($height < $oy) {
		$ox *= $height / $oy;
		$oy = $height;
	}

	$image->Resize(width => int($ox), height => int($oy));

	$image->Write($new_file);
	$self->save($new_file);
	unlink $new_file;
}

=begin nd
Method: save ($filename)
	Сохранение файла из файловой системы или с DAV сервера.
	Имя файла остаётся прежним. 
	Конфликты с дуюлями не отслеживаются TBD

Parameters:
	$filename - полный путь к сохраняемому файлу
=cut
sub save {
	my ($either, $filename) = @_;

	given ($either->C->{fileTransport}) {
		when ('LOCAL') {
			my $archive = $either->C->{archive};
			copy($filename, $archive) or warn "INPUT: Can't copy $filename to $archive: $!";
		}
		when ('DAV') {
			my $dav = WooF::Nginx->new;
			$dav->put(basename($filename), $filename);
		}
		default {
			warn "FILE|ERR: Unknown value in the fileTransport config.";
		}
	}
}

=begin nd
Method: upload ($field)
	Загрузка файла, полученного в HTTP запросе. Метод класса.
	Сохраняет загруженный файл в файловой системе или на DAV файл-сервере в зависимости от конфигурации.
	Создаёт уменьшенную копию загруженной фотографии для preview.

Parameters:
	$field - Название поля в форме HTML, с помощью которой был отправлен запрос. Например, 'driver.avatar'

Returns:
	- Загруженный файл. Ссылка на экземпляр <WooF::File>
	- undef, если возникли какие-либо проблемы
=cut
sub upload {
	my ($class, $field) = @_;

	my $request = $class->S->{request};
	my ($fh, $tmp_file) = tempfile('imageXXXXXX', DIR => $class->C->{tmp_dir});

	# Когда будет новая схема реквестов, это надо будет переписать на общий метод, перегруженный в потомках реквеста
	if ($request->isa('WooF::HTTPRequest::PSGI')) {
		my $uploads = $request->uploads;
		$field = "recent.$1" if !exists $uploads->{$field} && $field =~ /\.(.*?)$/;
		my $tempfile = $uploads->{$field}->tempname;
		copy $tempfile, $tmp_file;
		chmod 0644, $tmp_file;

		# В потоке заменить объект файла на его имя, чтобы не было проблем с JSON
		my @keys = split '\.', $field;
		my $last = pop @keys;

		my $target = $class->S->I;
		$target = $target->{$_} for @keys; #!!! меняет поток
		$target->{$last} = $uploads->{$field}->filename;
	} else {
		my $cgi = $class->S->cgi;
		return warn "INPUT: CGI does't has param: '$field' required by upload" unless $cgi->param($field);

		my $lightweight_fh = $cgi->upload($field);
		my $handler = $lightweight_fh->handle;
		my $buffer;
		while ($handler->read($buffer, 1024)) {
			unless (print $fh $buffer) {
				warn "FILE|ERR: Can't put file in tmp_dir ($field): $!";
				return;
			}
		}
	}
	close $fh or return warn "Can't close file for $field: $!";

	$tmp_file;
}

1;
