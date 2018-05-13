#!perl

system("clear");
use Term::ANSIColor qw(:constants);
print GREEN "Sistema operatiu:\n", RESET;
print "$^O\n";

#glob "C:\*.*";
#while (glob("C:\*")) {
#glob "/*";
print "Directori arrel:\n";
while (glob("/*")) {
	print "$_\n";
}
print "Argument:\n";
print "@ARGV[0]\n";