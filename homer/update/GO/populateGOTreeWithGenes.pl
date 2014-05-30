#!/usr/bin/perl -w

if (@ARGV < 3) {
	print STDERR "<tree> <terms file> <gene2go> [organism id | HG]\n";
	exit;
}

my %def = ();
open IN, $ARGV[1];
while (<IN>) {
	chomp;
	s/\r//g;
	my @line = split /\t/;
	$def{$line[0]} = $line[1];
}
close IN;
	

my %ontology = ();
my %terms = ();
my %alt = ();

open IN, $ARGV[0];
while (<IN>) {
	chomp;
	my @line = split /\t/;
	my @nodes = split (/\,/, $line[1]);
	$ontology{$line[0]} = \@nodes;
	if (!exists($terms{$line[0]})) {
		my %a = ();
		$terms{$line[0]} = \%a;
		$alt{$line[0]} = $line[0];
	}
	foreach(@nodes) {
		if (!exists($terms{$_})) {
			my %a = ();
			$terms{$_} = \%a;
			$alt{$_} = $_;
		}
	}
		
}
close IN;

open IN, $ARGV[1];
while (<IN>) {
	chomp;
	my @line = split /\t/;
	my $id = $line[0];
	next if (!exists($terms{$id}));
	next if (@line < 3);
	next if ($line[2] eq '');
	my @alt = split /\,/, $line[2];
	foreach(@alt) {
		$alt{$_} = $id;
	}
}
close IN;

my $numDefs = 0;
open IN, $ARGV[2];
while (<IN>) {
	chomp;
	my @line = split /\t/;

	#for ebi
	#my $geneID = $line[0];
	#my $goID = $line[1];

	#for gene2go
	next if (@line < 3);
	my $geneID = $line[1];
	my $goID = $line[2];
	my $taxID = $line[0];

	if (@ARGV > 3) {
		if ($ARGV[3] eq 'HG') {
			$geneID = $line[0];
			$goID = $line[1];
			next if (@line < 2);
		} else {
			next if ($taxID ne $ARGV[3]);
		}
	}

	if (!exists($alt{$goID})) {
		if (!exists($def{$goID})) {
			#print STDERR "@line\n";
		}
		next;
	}
$numDefs++;
	$terms{$alt{$goID}}->{$geneID} = 1;
}
close IN;
#print STDERR "$numDefs\n";

my %GENES = ();
printGenes('root');


sub printGenes {
	my ($node) = @_;
	if (exists($GENES{$node})) {
		return $GENES{$node};
	}
	my %genes = ();
	if (exists($ontology{$node})) {
		foreach(@{$ontology{$node}}) {
			my $g = printGenes($_);
			foreach(keys %$g) {
				$genes{$_} =1;
			}
		}
	}
	foreach(keys %{$terms{$node}}) {
		$genes{$_} =1;
	}
	my @genes = keys %genes;
	if (@genes > 0) {
		my $term = "NA";
		if (exists($def{$node})) {
			$term = $def{$node};
		}
		print "$node\t$term\t";
		my $c = 0;
		foreach(keys %genes) {
			print "," if ($c > 0);
			$c++;
			print "$_";
		}
		print "\n";
	}
	$GENES{$node} = \%genes;
	return \%genes;
}
