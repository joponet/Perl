#!/usr/bin/perl

use Term::ANSIColor;
use Term::ReadKey;

$clear = "\e[2J"."\e[0;0H";
$eraseline ="\e[0K";
$cursoron ="\e[?25h";
$cursoroff ="\e[?25l";
	
my $func = $ARGV[0];
my $fitxer = $ARGV[1];
my $in;
my @st; #variable estat per ecu
$func=$func?$func:"-h";

print $clear;

if ($fitxer)
{
	print color "green";
	printf("Fitxer: %s\n",$fitxer);
	print color "reset";
	open($in, "<", $fitxer) or die "Fitxer notrobat\n";
	binmode($in);
	raw() if $func =~ /-r/;
	formated() if $func =~ /-f/;
	encoded() if $func =~ /-e/;
	monitor() if $func =~ /-m/;
	close $in;
}

help() if $func =~ /-h/;
conf() if $func =~ /-c/;
ecutest() if $func =~ /-t/;

sub help
{
	print color "green";
	print "Help:\n";
	print "sequencia.pl OPCIO [FITXER]\n";
	print "-h: aquest ajut\n";
	print "-r: volcat raw\n";
	print "-f: amb format, una linia cada 0x00\n";
	print "-e: codificat i filtrat\n";
	print "-m: mode monitor\n";
	print "-c: configura port\n";
	print color "reset";
	print $cursoron;
	ReadMode("normal");
}

sub conf
{
	exec("stty -F /dev/ttyUSB0 speed 19200 cs8 parenb -parodd");
}

sub raw
{
	my $cont = 1024;
	my $byte;
	my $num=0;
	while (read($in,$byte,1) && $cont)
	{
		printf("%v02X ",$byte);
		$num++;
		$cont--;
		if (($num%20) == 0)
		{
			print("\n");
			#$num=0;
		}
	}
	print("\n");
}

sub formated
{
	my $key;
	my $byte;
	ReadMode("cbreak");
	while (read($in,$byte,1) && ($key !~ /q/))
	{
		printf("%v02X ",$byte);
		if (($byte =~ /\x00/))
		{
			print("\n");
			$key = ReadKey(-1);
		}
	}
	ReadMode("normal");}

sub encoded
{
	my $byte;
	my $fi1;
	my $fi2;
	my $cont=0;
	my $tot=0;
	
	while (read($in,$byte,2))
	{	
		if ($byte =~/\x10\x02/)
		{
			$cont++;
			printf("(%3d) ",$tot);
			printf("%*v2.2X ",' ',$byte);
			$fi1=\x00;
			$fi2=\x00;
			while($fi1 !~ /\x10/ && $fi2 !~ /\x03/)
			{
				read($in,$byte,1);
				printf("%v02X ",$byte);
				$fi1=$fi2;
				$fi2=$byte;
			}
			read($in,$byte,1);
			printf("%v02X ",$byte);
			print("\n");
		}
		if ($byte =~ /\x00/)
		{
			$tot++;
		}
	}
	printf("%d entrades\n",$cont);
}

sub monitor
{
	my $byte;
	my $cont=0;
	my @subcont;
	my $tot=0;
	my $key="";
	my $i;
	my $st1 = xFF;
	my $st2 = xFF;
	$| = 1;
	print $cursoroff;
	ReadMode("cbreak");

	while (read($in,$byte,1) && ($key !~ /q/))
	{	
		$i=0;
		$key = ReadKey(-1);
		if ($byte =~/\x00/)
		{
			monitoraux($i,$cont,$byte,$subcont[$i],0)
		} 
		else
		{
			read($in,$byte2,1);
			$byte = $byte.$byte2;
			$i++; monitoraux($i,$cont,$byte,$subcont[$i],4)
				if ($byte =~/\xF7\x7F/);
			$i++; monitoraux($i,$cont,$byte,$subcont[$i],6)
				if ($byte =~/\x7F\xF7/);
			$i++; monitoraux($i,$cont,$byte,$subcont[$i],4)
				if ($byte =~/\x7B\xE6/);
			$i++; monitoraux($i,$cont,$byte,$subcont[$i],6)
				if ($byte =~/\x7F\x7B/);
			$i++; monitoraux($i,$cont,$byte,$subcont[$i],4)
				if ($byte =~/\x76\x7F/);
			$i++; monitoraux($i,$cont,$byte,$subcont[$i],6)
				if ($byte =~/\x7F\x76/);
			$i++; monitoraux($i,$cont,$byte,$subcont[$i],4)
				if ($byte =~/\xBD\xE6/);
			ecu($key) if ($byte =~/\xBD\xE6/);
			$i++; monitoraux($i,$cont,$byte,$subcont[$i],7)
				if ($byte =~/\x7F\xBD/);
		}
	}
	print "\e[20;1H";
	printf("%d entrades\n",$cont);
	print $cursoron;
	ReadMode("normal");
}

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
	my $color=$_[5];

	$color="reset" if (!$color);

	print color $color;
	print "\e[".$row.";1H";
	printf("\r(%3d) ",$subcont);
	printf("%*v2.2X ",' ',$byte);
	while($len>0)
	{
		read($in,$byte,1);
		printf("%v02X ",$byte);
		$len--;
	}
	print color "reset";
	print $eraseline;
}

sub ecutest
{
	my $key="";
	$st[0] = 0xAF;
	$st[1] = 0xBF;
	$st[2] = 0xBF;
	$st[3] = 0xBF;
	$st[4] = 0xBF;
	$st[5] = 0x0F;
	ReadMode("cbreak");
	print $cursoroff;
	while ($key !~ /q/)
	{
		$key = ReadKey(-1);
		ecu($key);
		sleep(0.5);
	}
	ReadMode("normal");
	print $cursoron;
	print color "reset";
	print "fi";
}

sub ecu
{
	my $key = $_[0];
	my $color = green;
	my $row = 15;
	print color $color;
	print "\e[".$row.";1H";
	printf("%2.2X %2.2X %2.2X %2.2X %2.2X %2.2X\n",$st[0],$st[1],$st[2],$st[3],$st[4],$st[5]);
	#print("\n");
	print("Habilitada\n");
	print("Oberta\n");
}

