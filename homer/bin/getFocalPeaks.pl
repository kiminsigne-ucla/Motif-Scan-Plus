#!/usr/bin/env perl
use warnings;

if (@ARGV < 1) {
	print STDERR "<peaks.centered.txt> [ratio threshold | 0.75]\n";
	exit;
}

my $thresh = 0.75;
if (@ARGV > 1) {
	$thresh = $ARGV[1];
}
my $total=0;
my $good =0;
my $count = 0;
open IN, $ARGV[0];
while (<IN>) {
	$count++;
	next if (/^#/);
	if ($count < 2) {
		print $_;
		next;
	}
	chomp;
	s/\r//g;
	my $og = $_;
	my @line = split /\t/;
	next if (@line < 7);
	$total++;
	if ($line[6] >= $thresh) {
		print "$og\n";
		$good++;
	}
}
my $percent = $good/$total;
print STDERR "\n\tGood: $good/$total ($percent)\n\n";
