#!/usr/bin/perl -w

if (@ARGV < 2) {
	print STDERR "<taxid> <org> [extra file] ...\n";
	print STDERR " i.e. feature <tab> locuslink \n";
	exit;
}
my $org = $ARGV[1];
my $dir = "data/";

my $taxid = $ARGV[0];

my %unigene = ();
my %gene = ();
my %ensembl = ();
my %refseq = ();

my %geneIDs = ();
my %unigeneIDs = ();
my %refseqIDs = ();
my %ensemblIDs = ();

print STDERR "\tparsing gene2accession\n";
open IN, "gene2accession";
while (<IN>) {
	chomp;
	s/\r//g;
	my @line = split /\t/;
	my $oid = $line[0];
	next if ($oid ne $taxid);
	my $locus = $line[1];
	$geneIDs{$locus} = 1;
	$gene{$locus} = $locus;

	my @ids = ();
	push(@ids, $line[3]);
	push(@ids, $line[5]);
	push(@ids, $line[7]);
	for (my $i=0;$i<@ids;$i++) {	
		$ids[$i] =~ s/\.(.*)$//;
		next if ($ids[$i] eq '-');
		next if ($ids[$i] eq '');
		$gene{$ids[$i]} = $locus;
	}
}
close IN;

print STDERR "\tparsing gene2unigne\n";
open IN, "gene2unigene";
while (<IN>) {
	chomp;
	s/\r//g;
	my @line = split /\t/;
	next if (!exists($geneIDs{$line[0]}));
	$gene{$line[1]} = $line[0];
	$unigene{$line[0]} = $line[1];
}
close IN;

print STDERR "\tparsing gene2refseq\n";
open IN, "gene2refseq";
while (<IN>) {
	chomp;
	s/\r//g;
	my @line = split /\t/;
	next if ($line[0] ne $taxid);
	my $locus = $line[1];
	$geneIDs{$locus} = 1;
	$gene{$locus} = $locus;
	
	my $mrna = $line[3];
	my $prot = $line[5];
	$mrna =~ s/\.(.*)$//;
	next if ($mrna eq '-');
	next if ($mrna eq '');
	$gene{$mrna} = $locus;
	if (!exists($refseq{$locus})) {
		$refseq{$locus} = $mrna;
	}
}
close IN;

print STDERR "\tparsing gene2ensembl\n";
open IN, "gene2ensembl";
while (<IN>) {
	chomp;
	s/\r//g;
	my @line = split /\t/;
	my $oid = $line[0];
	next if ($oid ne $taxid);
	my $locus = $line[1];
	$geneIDs{$locus} = 1;
	$gene{$locus} = $locus;

	my @ids = ();
	push(@ids, $line[2]);
	push(@ids, $line[4]);
	push(@ids, $line[6]);
	for (my $i=0;$i<@ids;$i++) {	
		$ids[$i] =~ s/\.(.*)$//;
		next if ($ids[$i] eq '-');
		next if ($ids[$i] eq '');
		$gene{$ids[$i]} = $locus;
	}
}
close IN;



my %orfs = ();
my %names = ();

print STDERR "\tparsing gene_info\n";
open IN, "gene_info";
while (<IN>) {
	chomp;
	s/\r//g;
	my @line = split /\t/;
	next if ($line[0] ne $taxid);
	my $locus = $line[1];
	$geneIDs{$locus} = 1;
	$gene{$locus} = $locus;
	if ($line[5] =~ /Ensembl\:(.*\d?)\|*/) {
		my $ensb = $1;
		my @ids = split /\|/, $ensb;
		foreach(@ids) {
			s/Ensembl\://;
			s/^\s*//;
			s/\s*$//;
			$gene{$_} = $locus;
			if (!exists($ensembl{$locus})) {
				$ensembl{$locus} = $_;
			}
		}
	}
	my $name = $line[2];
	my $orf = $line[3];
	my $alias = $line[4];
	if ($orf ne '' && $orf ne '-') {
		$gene{$orf} = $locus;
		$orfs{$locus} = $orf;
	}
	if ($name ne '' && $name ne '-') {
		$gene{$name} = $locus;
		$names{$locus} = $name;
	}
	
	my $desc = "\t$name\t$alias\t$orf\t$line[7]\t$line[8]\t$line[9]\n";
	$description{$locus} = $desc;
}
close IN;

print STDERR "\tLooking through gene_history\n";
open IN, "gene_history";
while (<IN>) {
	chomp;
	s/\r//g;
	my @line = split /\t/;
	next if ($line[0] ne $taxid);
	my $locus = $line[1];
	my $old = $line[2];
	$gene{$old} = $locus;
	if (exists($geneIDs{$old})) {
		print STDERR "geneIDs contains old gene ids!!\n";
	}
	#$geneIDs{$old} = $locus;
}
close IN;
	



my $descHeader = "\tname\talias\torf\tchromosome\tdescription\ttype\n";

for(my $i=2;$i<@ARGV;$i++) {
	print STDERR "\tParsing $ARGV[$i]\n";
	open IN, $ARGV[$i];
	while (<IN>) {
		chomp;
		s/\r//g;
		s/\"//g;
		my @line = split /\t/;
		if ($line[1] =~ /^(..\.\d+)/) {
			$line[1] = $1;
		} else {
			$line[1] =~ s/\.(.*?)$//;
		}
		if (!exists($gene{$line[1]})) {
			#print STDERR "$line[0]\t$line[1]\n";
			next;
		}
		$gene{$line[0]} = $gene{$line[1]};
	}
	close IN;
}

print STDERR "\tOutputing data\n";
open OUT, ">$org" . "2gene.tsv";
foreach (keys %gene) {
	my $acc = $_;
	my $gid = $gene{$acc};
	print OUT "$acc\t$gid";
	my $ug = '';
	if (exists($unigene{$gid})) {
		$ug = $unigene{$gid};
	}
	if ($org eq 'yeast') {
		if (exists($orfs{$gid})) {
			#$ug = $orfs{$gid};
		}
	}
	print OUT "\t$ug";

	my $refseq = '';
	if (exists($refseq{$gid})) {
		$refseq = $refseq{$gid};
	}
	print OUT "\t$refseq";

	my $ensembl = '';
	if (exists($ensembl{$gid})) {
		$ensembl = $ensembl{$gid};
	}
	print OUT "\t$ensembl";

	my $orf = "";
	if (exists($orfs{$gid})) {
		$orf = $orfs{$gid};
	}
	print OUT "\t$orf";

	my $name = "";
	if (exists($names{$gid})) {
		$name = $names{$gid};
	}
	print OUT "\t$name";
	print OUT "\n";
}
close OUT;

open OUT, ">$org.description";
print OUT "GeneID\tUnigene\tRefSeq\tEnsembl" . $descHeader;
foreach(keys %description) {
	my $gid = $_;
	print OUT "$gid";
	my $ug = '';
	if (exists($unigene{$gid})) {
		$ug = $unigene{$gid};
	}
	print OUT "\t$ug";
	my $refseq = '';
	if (exists($refseq{$gid})) {
		$refseq = $refseq{$gid};
	}
	print OUT "\t$refseq";
	my $ensembl = '';
	if (exists($ensembl{$gid})) {
		$ensembl = $ensembl{$gid};
	}
	print OUT "\t$ensembl";
	print OUT "$description{$gid}";
}
close OUT;

