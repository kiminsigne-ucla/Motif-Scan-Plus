#!/usr/bin/perl -w
#
if (@ARGV < 1) {
	print STDERR "<OBO format GO file>\n";
	print STDERR "Produces tree files for each GO tree, plus terms.tsv\n";
	exit;
}
my %ontology = ();
my %definition = ();
my %extra = ();
my @roots = ();

my $termFlag = 0;
my $name = '';
my $parents = '';
my $alt = '';
my $id = '';
my $dontSave = 0;
my $valid = 0;

open IN, $ARGV[0];
while (<IN>) {
	chomp;
	s/\r//g;
	if (/^\[Term\]/) {
		$termFlag = 1;
		$dontSave = 0;
		my @p = ();
		$parents = \@p;
		my @a = ();
		$alt = \@a;
		my $name = '';
		my $id = '';
		next;
	}

	if ($termFlag) {
		if (/^id: (GO.*?)$/) {
			$id = $1;
			next;
		} elsif (/^name: (.*?)$/) {
			$name = $1;
			next;
		} elsif (/^is_a: (GO.*?) /) {
			push(@$parents, $1);
			next;
		} elsif (/^is_obsolete\: true/) {
			$id = '';
			$termFlag = 0;
			next;
		} elsif (/^relationship: part_of (GO.*?) /) {
			push(@$parents, $1);
			next;
			#$dontSave = 1;
		} elsif ($_ eq '') {
			next if ($termFlag == 0);
			$termFlag = 0;
			next if ($dontSave);
			next if ($id eq '');
			my $d = {name=>$name};
			$definition{$id} = $d;
			my $numParents = @$parents;
			if ($numParents < 1) {
				#print STDERR "$id\t$name\t$numParents\n";
				push(@roots, $id);
			}
			foreach(@$parents) {
				if (!exists($ontology{$_})) {
					my %a = ();
					$ontology{$_} = \%a;
				}
				$ontology{$_}->{$id} = 1;
			}
		}
	}
	
}
close IN;

my %done = ();
foreach(@roots) {
	#print STDERR "+++++++++ $_\t$definition{$_}->{'name'}\n";
	my $name = $definition{$_}->{'name'};
	open OUT, ">$name.tree";
	print OUT "root\t$_\n";
	printTree($_);
	close OUT;
}
open OUT, ">terms.tsv";
foreach(keys %definition) {
	my $id = $_;
	print OUT "$_\t$definition{$_}->{'name'}\t";
	my @all = ();
	foreach(@{$definition{$_}->{'alt'}}) {
		push(@all, $_);
	}
	if (exists($extra{$id})) {
		push(@all, $_);
	}
	my $c =0;
	foreach(@all) {
		print OUT "," if ($c >0);
		$c++;
		print OUT "$_"
	}
	print OUT "\n";
}

sub printTree {
	my ($node) = @_;
	return if (!exists($ontology{$node}));
	return if (exists($done{$node}));
	my @a = keys %{$ontology{$node}};
	return if (@a < 1);
	print OUT "$node\t";
	my $c =0;
	foreach (@a) {
		print OUT "," if ($c > 0);
		$c++;
		print OUT "$_";
	}
	print OUT "\n";
	$done{$node} = 1;
	foreach(@a) {
		printTree($_);
	}
}
