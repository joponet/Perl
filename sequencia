#!/usr/bin/perl

use strict;
use bytes;
use Term::ANSIColor;
use Term::ReadKey;
use Digest::CRC;
use Time::HiRes qw(sleep);

my $clear = "\e[2J"."\e[0;0H";
my $eraseline ="\e[0K";
my $cursoron ="\e[?25h";
my $cursoroff ="\e[?25l";
	
my $func = $ARGV[0];
my $fitxer = $ARGV[1];
my $in;

my $idhost; #identificador de trama
my $iddetall;
my $ecocont;
$idhost="\x14\x01"; # comparació per caràcters
$iddetall="\x01\x14";
$ecocont=0;

my @st; #variable estat per ecu
$st[0] = 0x01;
$st[1] = 0x14;
$st[2] = 0x08;
$st[3] = 0x01;
$st[4] = 0x5D;
$st[5] = 0x00;
$st[6] = 0x00;
$st[7] = 0x00;

my @item; #posicions de control
my $itemx;
$itemx=0;

$item[$itemx++]= {TITOL=>"no Habilitada",POS=>4,ID=>0x04,TECLA=>"h",ROW=>12,COL=>60}; # bit
$item[$itemx++]= {TITOL=>"estrep Recollit",POS=>4,ID=>0x04,TECLA=>"r",ROW=>13,COL=>60}; # bit
$item[$itemx++]= {TITOL=>"no Emergencia",POS=>3,ID=>0x08,TECLA=>"e",ROW=>14,COL=>60}; # bit
$item[$itemx++]= {TITOL=>"Tancada",POS=>3,ID=>0x04,TECLA=>"q",ROW=>15,COL=>60}; # bit
$item[$itemx++]= {TITOL=>"no 3 Intents sens",POS=>4,ID=>0x40,TECLA=>"i",ROW=>16,COL=>60}; # bit
$item[$itemx++]= {TITOL=>"estrep oK",POS=>4,ID=>0x20,TECLA=>"K",ROW=>17,COL=>60}; # bit
$item[$itemx++]= {TITOL=>"porta Ok",POS=>4,ID=>0x04,TECLA=>"o",ROW=>18,COL=>60}; # bit
$item[$itemx++]= {TITOL=>"Atrapament",POS=>5,ID=>0x80,TECLA=>"t",ROW=>19,COL=>60}; # bit
$item[$itemx++]= {TITOL=>"porta Tancant",POS=>5,ID=>0x01,TECLA=>"t",ROW=>12,COL=>1}; # bit
$item[$itemx++]= {TITOL=>"estrep recoLlint",POS=>5,ID=>0x04,TECLA=>"l",ROW=>13,COL=>1}; # bit
$item[$itemx++]= {TITOL=>"porta Averia",POS=>5,ID=>0x08,TECLA=>"a",ROW=>14,COL=>1}; # bit

$func=$func?$func:"-h";

print $clear;

if ($fitxer) {
	print color "green";
	printf("Fitxer: %s\n",$fitxer);
	print color "reset";
#	open($in, "<", $fitxer) or die "Fitxer notrobat\n";
#	open($in, "+>", $fitxer) or die "Fitxer notrobat\n";
	binmode($in);
	raw() if $func =~ /-r/;
	formated() if $func =~ /-f/;
	encoded() if $func =~ /-e/;
	monitor() if $func =~ /-m/;
	ecotest() if $func =~ /-t/;
	close $in;
}
else {
	help() if $func =~ /-h/;
	conf() if $func =~ /-c/;
	ecotest() if $func =~ /-t/;
}

# restaura pantalla - fi programa
print "\e[24;1H";
ReadMode("normal");
print $cursoron;
print color "reset";

sub help {
	print color "green";
	print "Help:\n";
	print "sequencia OPCIO [FITXER]\n";
	print "-h: aquest ajut\n";
	print "-r: volcat raw\n";
	print "-f: amb format, una linia cada 0x00\n";
	print "-e: codificat i filtrat\n";
	print "-m: mode monitor\n";
	print "-me: monitor amb echo";
	print "-c: configura port\n";
	print "-t: test eco\n";
	print color "reset";
	print $cursoron;
	ReadMode("normal");
}

sub conf {
	exec("stty -F /dev/ttyUSB0 speed 19200 cs8 parenb -parodd");
}

#monitor de comunicacions
sub monitor {
	my $byte;
	my $byte2;
	my $cont=0;
	my @subcont;
	my $tot=0;
	my $key="";
	my $i;
	$| = 1;
	print $cursoroff;
	ReadMode("cbreak");

	while (read($in,$byte,1) && ($key !~ /q/)) {	
		$i=0;
		$key = ReadKey(-1);
		if ($byte =~ /\x01|\x11|\x12|\x13|\x14/) {
			read($in,$byte2,1);
			$byte = $byte.$byte2;
		}
		# detall i resposta des de pc si /-me/
		$i++; monitoraux($i,$cont,$byte,$subcont[$i],4,$key)
			if ($byte =~/\x11\x01/);
		$i++; monitoraux($i,$cont,$byte,$subcont[$i],6,$key,"blue")
			if ($byte =~/\x01\x11/);
		$i++; monitoraux($i,$cont,$byte,$subcont[$i],4,$key)
			if ($byte =~/\x12\x01/);
		$i++; monitoraux($i,$cont,$byte,$subcont[$i],6,$key,"blue")
			if ($byte =~/\x01\x12/);
		$i++; monitoraux($i,$cont,$byte,$subcont[$i],4,$key)
			if ($byte =~/\x13\x01/);
		$i++; monitoraux($i,$cont,$byte,$subcont[$i],6,$key,"blue")
			if ($byte =~/\x01\x13/);
		$i++; monitoraux($i,$cont,$byte,$subcont[$i],4,$key)
			if ($byte =~/\x14\x01/);
		$i++; monitoraux($i,$cont,$byte,$subcont[$i],6,$key,"blue")
			if ($byte =~/\x01\x14/);
		sleep(1);
	}
	print "\e[20;1H";
	printf("%d entrades\n",$cont);
	print $cursoron;
	ReadMode("normal");
}

# monitor auxiliar, mostra cadena en pantalla
sub monitoraux
{
	my $i=$_[0];
	my $j;
	my $row=$i+3;
	$_[1]++; #cont
	my $byte=$_[2];
	$_[3]++;
	my $subcont=$_[3];
	my $len=$_[4];
	my $key=$_[5];
	my $color=$_[6];
	my $data;
	my $cadena;

	$color="reset" if (!$color);
	$color="red" if ($byte =~ /$iddetall/);
	print color $color;
	print "\e[".$row.";1H";
	printf("\r(%3d) ",$subcont);
	printf("%*v2.2X ",' ',$byte);
	$cadena = $byte;
	# llegeix resta cadena
	while($len>0)
	{
		read($in,$data,1);
		printf("%v02X ",$data);
		$cadena .= $data;
		$len--;
	}
	print color "reset";
	print $eraseline;
	if (($byte =~ $idhost) && ($func =~ /-me/)) {
		eco($key);
		monitoreco($i+1);
		monitordet();
	}
	if ($byte =~ /$iddetall/) {
		for $j (0..7) {
			$st[$j] = ord(substr($cadena,$j,1));
		}
		monitordet();
	}
}

# monitor, mostra detall de senyals
sub monitordet {
	my $coloroff = "black";
	my $coloron = "green";
	my $color;

	# mostra titols
	for my $it (@item) {
		if (($st[$it->{POS}] & $it->{ID}) == $it->{ID}) {print color $coloron;}
		else {print color $coloroff}
		print "\e[".$it->{ROW}.";".$it->{COL}."H";
		print $it->{TITOL}."\n";
	}
}

# mostra en pantalla
sub monitoreco {
	my $row;
	$row=$_[0]+3;
	$ecocont++;
	print color "red";
	printf ("\e[".$row.";1H(%3d) ",$ecocont);
	for my $stx (@st) {
		printf("%02X ",$stx);
	}
}

sub ecotest
{
	my $key="";
	my $cont;
	ReadMode("cbreak");
	print $cursoroff;
	while ($key !~ /q/)
	{
		$key = ReadKey(-1);
		eco($key);
		monitoreco($cont);
		monitordet();
		sleep(0.5);
	}
}

sub eco
{
	my $key = $_[0];

	# canvia bits si "key"
	for my $it (@item) {
		if ($key =~ /$it->{TECLA}/) {change($it)}
	}

	# calcula CRC
	my $crc = Digest::CRC->new(type=>"crcccitt", poli=>0x1021, init=>0x0000);
	for my $sti (0..5) {
		$crc->add(chr($st[$sti]));
	}

	# guarda CRC a cadena 
	my $scrc;
	$scrc = $crc->digest;
	$st[6] = $scrc >> 8;
	$st[7] = $scrc & 0xFF;

	# output a fitxer en binari 
	if (($fitxer) && ($func =~/-me|-t/)) {
		for my $stx (@st) {
			print $in chr($stx);
		}
	}
}

sub change
{
	my $it = $_[0];
	my $st = $st[$it->{POS}];
	my $id = $it->{ID};
	my $val = $st & $id;
	if ($val == 0) {$st = $st | $id;}
	else {$st = $st & (~$id);}
	$st[$it->{POS}] = $st;	
}

