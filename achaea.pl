#!/usr/bin/perl -w

use strict;
use vars qw($VERSION %IRSSI);

$VERSION = "20100423";
%IRSSI = (
	authors			=>	"Christoffer Madsen",
	contact			=>	"dodder\@gmail.com",
	name			=>	"achaea.pl",
	description   	        =>	"IRSSI Achaean Plugin, let's you play Achaea within Irssi.",
	license			=>	"GPL",
	changed			=>	"$VERSION"
);

use Irssi;
use Net::Telnet;

our $windowName = "<Achaea>";
our $telnet = new Net::Telnet(Timeout => 10);

our $window = Irssi::Windowitem::window_create($windowName, 1);
$window->set_name($windowName);

$telnet->open("achaea.com");

Irssi::timeout_add(500, \&output, undef);
Irssi::signal_add("send command", \&sendcmd);

# Declaring Variables
                my $health;
                my $mana;
                my $prompt;
                my $equilibrium;
                my $health;
                my $balance;
                my $action;
		my $jerk;
sub output {
	while(my $line = $telnet->getline(Timeout => 0, Errmode => "return")) {
#		chomp($line);
#		chomp($line);chomp($line);chomp($line);$line.="\n";
#		$line =~ s/\n*$/\n/;
		$line =~ s/\n*$//;
#		$line =~ s:(.*)w (.*)-(.*):(.*)w (.*)-\n:;
#		$line =~ s/ex-/ex-\n/;
		#$window->print($line);
		#$server->print($string, MESSAGELEVEL_CLIENTCRAP);
		$window->print($line, MSGLEVEL_CLIENTCRAP);
		
		# Basic Achaean fishing regexes.
		# Prompt regex and settings.
		if ($line =~ m/^(.*)h, (.*)m, (.*)e, (.*)w (.*)-/) { 
			$health = $1;
			$mana = $2;
			$prompt = $5;
			
			# Old checks, replaced and optimized.
			#$equilibrium = (index($prompt, 'x') >= 0);
			#$balance = (index($prompt, 'e') >= 0);
			
			$balance = $prompt =~ /x/ ? 1 : 0;
			$equilibrium = $prompt =~ /e/ ? 1 : 0;
			
			#$window->print("bal: $balance equi: $equilibrium health: $health mana: $mana prompt: $prompt");
			#if ($action > 0 && $balance == 1) { action(); }

			#balance()
		}
		# Balance Queue.
		sub balance
		{
		#$window->print("balance function loaded");
		if ($balance == 1 && $equilibrium == 1) {
			#$window->print("balance function if processed ($balance - $equilibrium)");
			action();
			}
		}
		# Action Queue
		sub action
		{
			#$window->print("action function loaded with: $action");
  			 if ($action) {
			$telnet->print("$action");
			$action = 0;
			}
		}
		sub actions
		{
			($action) = @_;
			balance();
		}

		if ($line =~ m/You have recovered balance on all limbs./) {$balance = 1; balance()}
		# Fishing Triggers	
		if ($line =~ m/Relaxing the tension on your line, you are able to reel again./) { actions("reel line") }
		if ($line =~ m/You feel a fish nibbling on your hook./) { delay("tease line") }
		if ($line =~ m/You (.*) fish (.*) a (.*) strike at your bait./) {$jerk = 1; actions("jerk pole")}
		if ($line =~ m/You quickly jerk back your fishing pole and feel the line go taut. You've hooked (.*)!/) {$balance = 0; $jerk = 0; actions("reel line")}
			       #You quickly jerk back your fishing pole and feel the line go taut. You've hooked an enormous fish!
		if ($line =~ m/You quickly jerk back your fishing pole, but the hook pulls free of the fish./) {$balance = 0; ++$jerk; if ($jerk<3) {actions("jerk pole")}}
		if ($line =~ m/You quickly jerk back your fishing pole, to no avail./) {++$jerk; if ($jerk<3) {actions("jerk pole")}}
		if ($line =~ m/With a style born of skill, you reel in a (.*) in a single smooth motion./) {bait()}
		if ($line =~ m/You quickly reel in (.*), landing it with ease!/) {bait()}
		if ($line =~ m/You reel in the last bit of line and your struggle is over./) {bait()}
		if ($line =~ m/With a final tug, you finish reeling in the line and land (.*)/) {bait()}
		if ($line =~ m/As the fish strains your line beyond its breaking point, it snaps suddenly, costing you your fish and bait./) {bait()}
		
		sub bait
		{
			#$telnet->print("put fish in bucket");
			$telnet->print("get bait from tank");
			$telnet->print("bait hook with bait");
			$window->print("Fishing: Ready to cast!",MSGLEVEL_HILIGHT);
			#disable line below for normal usage
			$balance = 0;
		#	actions("cast line medium")
		}

		sub delay
		{
			sleep 2;
			actions(@_)
		}
}
}

sub sendcmd {
	$window->set_name($windowName);
	my $thisWindow = Irssi::active_win;
	if($thisWindow->{name} eq $windowName) {
		$telnet->print($_[0]);
		&output;
	}
}
