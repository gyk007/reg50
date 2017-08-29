package ALKO::SendMail;

=nd begin
Package: ALKO::SendMail
	Модуль для отправки сообщений на электронную почту
=cut
use strict;
use warnings;
use Error;
use Encode;	                            # модуль для перекодирования строк
use Email::Sender::Simple qw(sendmail); # модуль  отправки email по протоколу SMTP
use Email::Sender::Transport::SMTP;     # модуль  отправки email по протоколу SMTP
use Email::Simple::Creator;             # модуль для создания email
use IO::Socket::SSL;                    # модуль для работы с SSL
use XML::Simple;                        # модуль для работы с XML
use Email::MIME::CreateHTML;            # модуль для создания email с файлами
use Template;                           # модуль Template Toolkit
use Digest::MD5 qw(md5_hex);            # модуль для работы с хэш
use utf8;
use base qw(Exporter);
our @EXPORT = qw(send_mail);

=begin nd
Function: send_mail($email)
	Функция отправки письма
Parameters:
	$email               - ссылка на хэш
	$email->{message}    - строка email
	$email->{from}       - адрес отправителя
	$email->{to}         - адрес получателя
	$email->{subject}    - заголовок
	$email->{template}   - имя шаблона, шаблоны находятся в email_templates.xml
	$email->{file}       - ссылка на хэш имя_файла => путь к файлу
	$email->{info}       - ссылка на хэш c дополнительной информацией
=cut
sub send_mail{
	my %email = %{shift()};
	$email{subject} = encode('MIME-Header', $email{subject});

	unless ($email{from}) {
		$email{from} = '"Alaskar Technologies" <info@alaskartech.com>';
	}

	# Шаблон письма
	if ($email{template}) {
		my $simple = XML::Simple->new();
		#считываем конфигфайл с именами и путями к еmail шаблонам
		my $templates = $simple->XMLin("$ENV{PWD}/conf/email_template.xml");
		#создаем html шаблон для email
		my $tt = Template->new({
			INCLUDE_PATH => "$ENV{PWD}/template/",
			INTERPOLATE  => 0,
			RELATIVE     => 1,
			ENCODING     => 'utf8'
		});
		$tt->process($templates->{"$email{template}"}, $email{info}, \$email{message}) or systemError('Template not found');
	} else {
		utf8::encode($email{message});
	}

	my $message;
	if ($email{file}) {
		# Создаем email и прекрепляем файл для отправки
		$message = Email::MIME->create_html(
			header => [
				From    => $email{from},
				To      => $email{to},
				Subject => $email{subject},
			],
			body    => $email{message},
			objects => $email{file}
		);
	} else {
		# Создаем email
		$message = Email::Simple->create(
			header =>[
				To             => $email{to},
				From           => $email{from},
				subject        => $email{subject},
				'Content-Type' => 'text/html',
			],
			body => $email{message}
		);
	}

	# Настройка SMTP
	my $transport = Email::Sender::Transport::SMTP->new({
		host          => 'mail.alaskartech.com',
		port          => '465',
		sasl_username => 'noreply@alaskartech.com',
		sasl_password => 'alaskaR&7',
		ssl           => 1
	});
	# Отправка email с помощью SMTP протокола
	sendmail($message, { transport => $transport });
}


1;