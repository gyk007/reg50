package WooF::Object::Constants;
use base qw / Exporter /;

=begin nd
Class: WooF::Object::Constants
	Константы, используемые в собственной объектной модели.
	
	Константы из <WooF::Object> вынесены в отдельный файл, чтобы исключить
	циклическое включение класса <WooF::Object> из класса, включенного в него самого.
	В частности, из <WooF::Object::Collection>, использующего данные константы.
=cut

use strict;
use warnings;

=begin nd
Variable: our @EXPORT
	Экспорт констант привязки к Базе Данных.
	См. <Constants>
=cut
our @EXPORT = qw/ NO_SYNC REMOVED NOSYNC DWHLINK MODIFIED OBJINIT DOSYNC /;

=begin nd
Constant: NO_SYNC
	Пользователь не хочет сохранять объект в базе никогда автоматически.
	Для установки флага конструктор вызывается с первыми аргументом My::Class->new(NO_SYNC, ...).
=cut
use constant {
	NO_SYNC => '__NO_SYNC__',
};

=begin nd
Constants: Константы для работы с внутренним состоянием экземпляра, хранящимся в специальном элементе хеша $self->{STATE};

Constant: REMOVED
	Если флаг установлен, то экземпляр был удален из хранилища.
	
Constant: NOSYNC
	Если флаг установлен, пользователь не хочет сохранять изменения экземпляра никогда автоматически. См. <NO_SYNC>
	
Constant: DWHLINK
	Флаг, указывающий, что экземпляр был загружен из базы данных.
	
Constant: MODIFIED
	Если экземпляр был загружен из базы (установлен <DWHLINK>), то установленный флаг говорит о том, что экземпляр был
	изменен после получения из базы или после последней синхронизацией с базой.
	
Constant: OBJINIT
	Устанавливает все флаги в начальное значение.
	
Constant: DOSYNC
	Маска для сброса флага <NO_SYNC>
=cut
use constant {
	REMOVED  => 0b0001,
	NOSYNC   => 0b0010,
	DWHLINK  => 0b0100,
	MODIFIED => 0b1000,

	OBJINIT  => 0b0000,
	DOSYNC   => 0b1101,
};

1;
