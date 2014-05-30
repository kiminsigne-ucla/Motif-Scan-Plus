#!/usr/bin/perl -w
#

if (@ARGV < 1) {
	print STDERR "Usage: human2gene.tsv\n";
	exit;
}
my %genes = ();
`wget -O CosmicCompleteExport_v67_241013.tsv.gz ftp://ftp.sanger.ac.uk/pub/CGP/cosmic/data_export/CosmicCompleteExport_v67_241013.tsv.gz`;
`gunzip CosmicCompleteExport_v67_241013.tsv.gz`;


my %conv = ();
open IN, $ARGV[0];
while (<IN>) {
	chomp;
	s/\r//g;
	my @line = split /\t/;
	$conv{$line[0]} = $line[1];
}
close IN;

open IN, "CosmicCompleteExport_v67_241013.tsv";
my $c = 0;
while (<IN>) {
	$c++;
	next if ($c < 2);
	chomp;
	s/\r//g;
	my @line = split /\t/;
	next if (@line < 10);
	my $id = $line[6] . "-" . $line[8] . "-" . $line[9];
	my $g = $line[0];

	if (!$conv{$g}) {
		next;
	}
	$g = $conv{$g};

	if (!exists($genes{$id})) {
		my %a = ();
		$genes{$id} = \%a;
	}
	$genes{$id}->{$g}=1;

}
close IN;

foreach(keys %genes) {
	my $id = $_;
	print "$id\t$id\t";
	my $c = 0;
	foreach(keys %{$genes{$id}}) {
		print "," if ($c > 0);
		$c++;
		print "$_";
	}
	print "\n";
	#print STDERR "$id\t$c\n";
}

`rm CosmicCompleteExport_v67_241013.tsv`;
