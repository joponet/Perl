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
	print color "reset";
	print $cursoron;
	ReadMode("normal");
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
	my $byte;
	while (read($in,$byte,1))
	{
		printf("%v02X ",$byte);
		if (($byte =~ /\x7F/) || ($byte =~ /\x7F/))
		{
			print("\n");
		}
	}
}

sub encoded
{
	my $byte;
	my $cont=0;
	my $tot=0;
	
	while (read($in,$byte,2))
	{	
		if ($byte =~/\x7F\xDD/)
		{
			$cont++;
			printf("(%3d) ",$tot);
			printf("%*v2.2X ",' ',$byte);
			while($byte !~ /\x00/)
			{
				read($in,$byte,1);
				printf("%v02X ",$byte);
			}
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
	$| = 1;
	print $cursoroff;
	ReadMode("cbreak");

	while (read($in,$byte,2) && ($key !~ /q/))
	{	
		$i=0; monitoraux($i,$cont,$byte,$subcont[$i],4)
			if ($byte =~/\x11\x01/);
		$i++; monitoraux($i,$cont,$byte,$subcont[$i],6)
			if ($byte =~/\x01\x11/);
		$i++; monitoraux($i,$cont,$byte,$subcont[$i],4)
			if ($byte =~/\x12\x01/);
		$i++; monitoraux($i,$cont,$byte,$subcont[$i],6)
			if ($byte =~/\x01\x12/);
		$i++; monitoraux($i,$cont,$byte,$subcont[$i],4)
			if ($byte =~/\x13\x01/);
		$i++; monitoraux($i,$cont,$byte,$subcont[$i],6)
			if ($byte =~/\x01\x13/);
		$i++; monitoraux($i,$cont,$byte,$subcont[$i],4)
			if ($byte =~/\x14\x01/);
		$i++; monitoraux($i,$cont,$byte,$subcont[$i],6)
			if ($byte =~/\x01\x14/);
		$i++; monitoraux($i,$cont,$byte,$subcont[$i],4)
			if ($byte =~/\x15\x01/);
		$i++; monitoraux($i,$cont,$byte,$subcont[$i],6)
			if ($byte =~/\x01\x15/);
		$i++; monitoraux($i,$cont,$byte,$subcont[$i],4)
			if ($byte =~/\x16\x01/);
		$i++; monitoraux($i,$cont,$byte,$subcont[$i],6)
			if ($byte =~/\x01\x16/);
		$i++; monitoraux($i,$cont,$byte,$subcont[$i],6,"red")
			if ($byte =~/\x7F\xD7/);
		$i++; monitoraux($i,$cont,$byte,$subcont[$i],6)
			if ($byte =~/\x7F\xD9/);
		$key = ReadKey(-1);
		if ($byte =~ /\x00/)
		{
			$tot++;
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
	while($len)
	{
		read($in,$byte,1);
		printf("%v02X ",$byte);
		$len--;
	}
	print color "reset";
	print $eraseline;
	sleep 1;
}

