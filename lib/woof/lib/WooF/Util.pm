package WooF::Util;
use base qw/ Exporter /;

=begin nd
Package: WooF::Util
	Различные полезные функции общего назначения.
	
	Модуль не объектно-ориентированный.
=cut

use strict;
use warnings;

use WooF::Error;

=begin nd
Variable: our @EXPORT
	Экспортируемые по дефолту имена
	- expose_hashes
	- split_by_3
	- trim
=cut
our @EXPORT = qw/ expose_hashes split_by_3 trim /;

=begin nd
Method: expose_hashes (\@hash)
	Раскрыть хэши в массиве.

	Фактически разыменовываются все ссылки на хеши, находящиеся в нечетных позициях массива
	и попутно исходный массив трансформируется в хеш.

	bless'нутые передавать нельзя.

Parameters:
	\@hash - хеш, упакованный в массив.

Returns:
	Ссылку на полученный хеш.
=cut
sub expose_hashes {
	my $src = shift;
	return warn "|ERR: exposeHashes() expects one argument exactly" if @_;
	return warn "|ERR: exposeHashes() expects arrayref" unless ref $src eq 'ARRAY';
	
	my (@dst, $position);
	for (@$src) {
		if (++$position % 2 and ref $_ eq 'HASH') {	# Имеем дело со сложным ключом, подлежащим раскрытию
			my ($k, $v); push @dst, $k, $v while ($k, $v) = each %$_;
			++$position;
		} else {
			push @dst, $_;
		}
	}

	+{@dst};		# без плюса получится не ссылка на хеш, а блок
}

=begin nd
Function: split_by_3 ($string)
	Разбивает строку с числом на десятичные разряды.

Parameters:
	$string - строка с числом.

Returns:
	Строку с числом, разбитым на разряды.
=cut
sub split_by_3 {
	my ($text) = @_;

	my $result = reverse $text;
	$result =~ s/(\d{3})(?=\d)(?!\d* )/$1 /g;
	$_[0] = reverse $result;
}

=begin nd
Function: trim ($string)
	Сокращает до минимума все пробельные символы в строке.
	- Обрезает все пробельные символы в начале строки.
	- Обрезает все пробельные символы в конце строки.
	- Заменяет последовательности из пробельных символов на один пробел.
	Функция полезна для обработки строк ввода юзера.
	Функция изменяет передаваемый aргумент!

Parameters:
	$string - строка, подлежащая обрезанию.

Retruns:
	Обработанную строку.
	Но обычно нет необходимости использовать возвращаемое значение.
=cut
sub trim {
	return unless @_ and defined $_[0];

	$_[0] =~ s/^\s*//;
	$_[0] =~ s/\s*$//;

	$_[0] = join(' ', split('\s+', $_[0]));
}

1;
