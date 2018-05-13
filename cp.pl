#!/usr/bin/perl
use Win32::Console::ANSI;
use Term::ANSIColor;
use Term::ReadKey;
use File::Copy;

my $discori="N";
my $discdest="F";

my $clear = "\e[2J"."\e[0;0H";
my $clearend = "\e[0J";
my $eraseline ="\e[0K";
my $cursoron ="\e[?25h";
my $cursoroff ="\e[?25l";
my $dirciso = "ciso";
my $key="";
my $quit=0;

print $cursoroff;
if ($ARGV[0] =~ /ciso/) {
	addciso();
}
else {
	system "start cp.pl ciso";
	extciso();
}
print $cursoron;

# extciso
sub extciso {
	
	my $nomlist="list.txt";
	my $list;
	my $filename="";
	my $ciso;
	my @cisolist;
	my $cisocount;

	print $clear;
	print color "green";
	print "Extreu wbfs de $discori\n";	
#	ReadMode("cbreak");

	open ($list,"<",$nomlist) or die "Fitxer list.txt no trobat";
	while (!eof($list) && !$quit) {
		$id = readline($list);
		chomp $id;
		print "\e[3;1H";
		print $clearend;
		print "$id\n";
		# per proves
		#copy ("list.txt","$id.ciso");
		# extreu
		system "wbfs_win $discori extract $id";
		opendir ($ciso,".");
		@cisolist = readdir ($ciso);
		@cisolist = grep (/\.ciso/,@cisolist);
		closedir ($ciso);
		$filename = @cisolist[0];
		chomp $filename;
		print "$filename\n";
		move ($filename,$dirciso);
		$key = ReadKey(-1);
		if ($key =~ /q/) {$quit=1;}
		else {sleep (1);}
		# comprova fitxers cua i espera
		$cisocount=100;
		while ($cisocount>5) {
			opendir $ciso,$dirciso;
			@cisolist= readdir $ciso;
			close $ciso;
			$cisocount = @cisolist;
			if ($cisocount>5) {
				print "\e[3;1H";
				print $clearend;
				print "espera\n";
				sleep 1;
			}
		}
	}
	close ($list);

#	ReadMode("normal");
	print color "reset";
}

# addciso
sub addciso {

	my $dirlist;
	my $file;

	print $clear;
	print color "green";
	print "Afegeix wbfs a $discdest\n";
#	ReadMode("cbreak");
	
	# chdir $dirciso;
	opendir $dirlist,$dirciso;
	while (!$quit) {
		$file = readdir $dirlist;
		if ($file) {
			chomp $file;
			print "\e[3;1H";
			print $clearend;
			print "$file\n";
			if ($file =~ /\.ciso$/) {
				system "wbfs_win $discdest add $dirciso\\$file"; 
				unlink "$dirciso\\$file";
			}
		}
		else {
			# reopen dir to update list
			closedir $dirlist;
			opendir $dirlist,$dirciso;
		}
		$key = ReadKey(-1);
		if ($key =~ /q/) {$quit=1;}
		else {sleep (1);}
	}
	closedir $dirlist;
	
#	ReadMode("normal");
	print color "reset";
}