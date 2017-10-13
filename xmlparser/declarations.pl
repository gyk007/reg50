#!/usr/bin/perl
use strict;
use File::Copy;
use IO::File;
use Encode;
use utf8;

use WooF::Error;
use WooF::Debug;
use ALKO::Client::Official;
use ALKO::Client::File;
use FindBin;
use File::Copy;
use IO::File;

# Получаем массив ИНН
my $taxcode = ALKO::Client::Official->All(taxcode => {});
my @arr_taxcode = keys %{$taxcode->Hash('taxcode')};

# Открываем все папки
opendir DIR, "$ENV{HOME}/data/i/declaration" or die $!;
	while(my $dname = readdir DIR) {
		unless (-e $dname) {
			opendir DIR2, "$ENV{HOME}/data/i/declaration/$dname" or die $!;

			while (my $dname2 = readdir DIR2) {
				unless (-e $dname2) {
					opendir DIR3, "$ENV{HOME}/data/i/declaration/$dname/$dname2" or die $!;

					while(my $dname3 = readdir DIR3) {
						unless (-e $dname3) {
							opendir DIR4, "$ENV{HOME}/data/i/declaration/$dname/$dname2/$dname3" or die $!;

							while(my $fname = readdir DIR4) {
									#debug $fname if ($fname ne '..' and $fname ne '.');
									my ($ext) = $fname =~ /\.([A-z0-9]+)$/;
									# Файлы формата xls
									if($ext eq 'xls') {



										for my $tax (@arr_taxcode) {
											# Создаем папку если ее не существует
											mkdir "$ENV{HOME}/www/backend/files/declaration/$tax"	unless -d "$ENV{HOME}/www/backend/files/declaration/$tax";

											if( $dname =~ /$tax/ ) {
       												my $path_from = "$ENV{HOME}/data/i/declaration/$dname/$dname2/$dname3/$fname";
													my $path_to   = $FindBin::Bin . "/../files/declaration/$tax";

       												my ($fname_without_ext) = split (".$ext", $fname);
       												utf8::decode($fname_without_ext);

       												# Проверяем существуте ли файл
       												my $file = ALKO::Client::File->Get(taxcode => $tax, name => $fname_without_ext);
       												# Копируем файл
       												unless ($file) {
       													my $size_file = (-s $path_from);

	       												$file = ALKO::Client::File->new({
	       													path    => "declaration/$tax",
	       													name    => $fname_without_ext,
	       													ext     => $ext,
	       													size    => $size_file,
	       													taxcode => $tax
	       												})->Save;

	       												my $id = $file->id;

	       												copy $path_from, "$path_to/$id.$ext";

	       												print "copy to /declaration/$tax/$id.$ext \n"
													}
											}

										}
									}

								}
								closedir DIR4;
							}
						}
						closedir DIR3;
					}
				}
			closedir DIR2;
		}
	}
closedir DIR;

1;