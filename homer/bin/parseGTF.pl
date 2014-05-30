#!/usr/bin/env perl
use warnings;

my $bufferSize= 2000;

if (@ARGV < 2) {
	print STDERR "\n\tUsage: parseGTF.pl <GTF format file> <mode> [options]\n";
	print STDERR "\n\tOutputs a homer-style position/peak file to stdout\n";
	print STDERR "\tMainly used by various other Homer programs\n";
	print STDERR "\n\t2nd argument modes:\n";
	print STDERR "\t\ttss: return TSS positions (+/- $bufferSize bp)\n";
	print STDERR "\t\ttts: return termination positions (+/- $bufferSize bp)\n";
	print STDERR "\t\texons: return exon positions\n";
	print STDERR "\t\tann: return file for using with assignGenomeAnnotation\n";
	print STDERR "\t\trna: return file for using with analyzeRNA.pl\n";
	print STDERR "\t\tgtf: return gtf file with no redundant transcript/gene IDs\n";
	print STDERR "\t\tanntable: returns tab-delimted table with attribute information for each gene ID\n";
	print STDERR "\n\tAdditional options:\n";
	print STDERR "\t\t-gff (input file is gff format-treats 9th column as ID)\n";
	print STDERR "\t\t-gff3 (input file is gff3 format - looks for parent attribute to assign gene name)\n";
	print STDERR "\t\t\n";
	print STDERR "\t\t-gid (use gene IDs as the primary identifier)\n";
	print STDERR "\t\t-tid (use transcript IDs as the primary identifier, default)\n";
	print STDERR "\t\t-removeAccVer (Normally any .1, .2, etc. at end of accession numbers, i.e. AT1G01040.2)\n";
	#print STDERR "\t\t-homerUniq (homer style unique IDs, i.e. -HOMER\#\n";
	print STDERR "\n";
	exit;
}

my $requireExons = 1;
my $gffFlag = 0;
my $gff3Flag = 0;
my $gidFlag = 0;
my $annTable = 0;
my $removeAccFlag = 0;
my $homerUniq = 1;
for (my $i=2;$i<@ARGV;$i++) {
	if ($ARGV[$i] eq '-gff') {
		$gffFlag = 1;	
		print STDERR "\tTreating input file as GFF file\n";
	} elsif ($ARGV[$i] eq '-gff3') {
		$gff3Flag = 1;	
		print STDERR "\tTreating input file as GFF3 file\n";
	} elsif ($ARGV[$i] eq '-gid') {
		$gidFlag = 1;
	} elsif ($ARGV[$i] eq '-tid') {
		$gidFlag = 0;
	} elsif ($ARGV[$i] eq '-homerUniq') {
		$homerUniq = 1;
	} elsif ($ARGV[$i] eq '-anntable') {
		$annTable = 1;
	} elsif ($ARGV[$i] eq '-removeAccVer') {
		$removeAccFlag = 1;
	}
}

if ($ARGV[1] eq 'anntable' || $annTable == 1) {
	print STDERR "\tParsing GTF to make an annotation table from attributes...\n";
	parseAnnTable($ARGV[0]);
	exit;
}

my @gtfLines = ();
%gidMapping = ();
open IN, $ARGV[0];
while (<IN>) {
	chomp;
	s/\r//g;
	next if (/^#/);
	next if (/^track/);
	next if (/^browser/);
	my @line = split /\t/;
	next if (@line < 9);
	my $chr = $line[0];
	my $col1 = $line[1];
	my $feature = $line[2];
	my $start = $line[3];
	my $end = $line[4];
	my $score = $line[5];
	my $strand = $line[6];
	$strand = "+" if ($strand eq '.');
	my $frame = $line[7];
	my $gid = '';
	my $tid = "";
	my @otherAtt = ();
	if ($gffFlag) {
		$gid = $line[8];
		$tid = $line[8];
	} else {
		my @attributes = split /\;/,$line[8];
		foreach(@attributes) {
			s/^\s*//;
			my @pair = ();
			if ($gff3Flag || $gffFlag) {
				@pair = split /=/,$_;
			} else {
				@pair = split / /,$_;
			}

			next if (@pair < 2);
			$pair[1] =~ s/\"//g;
			if ($pair[0] eq 'gene_id') {
				$gid = $pair[1];
			} elsif ($pair[0] eq 'transcript_id') {
				$tid = $pair[1];
			} elsif ($gff3Flag && $pair[0] eq 'Parent') {
				$gid = $pair[1];
				$tid = $pair[1];
			} else {
				push(@otherAtt, $_);
			}
		}
	}
	if ($removeAccFlag) {
		$tid =~ s/\.\d+$//;
		$gid =~ s/\.\d+$//;
	}
	my $d = {g=>$gid,t=>$tid,c=>$chr,s=>$start,e=>$end,score=>$score,d=>$strand,f=>$feature,fr=>$frame,o=>\@otherAtt,c1=>$col1};
	push(@gtfLines,$d);
	$gidMapping{$tid} = $gid;
}
@gtfLines = sort {$a->{'c'} cmp $b->{'c'} || $a->{'g'} cmp $b->{'g'} || $a->{'t'} cmp $b->{'t'} || $a->{'s'} <=> $b->{'s'} || $a->{'e'} <=> $b->{'e'}} @gtfLines;


my $mode = $ARGV[1];

if ($mode eq 'gtf') {
	printGTF(\@gtfLines);
}

my %good = ();
$good{'tts'}=1;
$good{'ann'}=1;
$good{'exons'}=1;
$good{'rna'}=1;
$good{'tss'}=1;
if (!exists($good{$mode})) {
	print STDERR "\t!!!! $mode is not a valid option!!!\n";
	exit;
}

my %gnames = ();
my %names = ();
my $currID = '';
my %genes = ();
my %ends = ();
foreach(@gtfLines) {
	my $chr = $_->{'c'};
	my $feature = $_->{'f'};
	my $start = $_->{'s'};
	my $end = $_->{'e'};
	my $score = $_->{'score'};
	my $strand = $_->{'d'};
	my $frame = $_->{'fr'};
	my $gid = $_->{'g'};
	my $tid = $_->{'t'};

	my $id = $tid;
	if ($gidFlag) {
		#$id = $gid;
	}

	if (exists($genes{$id})) {
		if ($genes{$id}->{'c'} eq $chr) {
			next if ($genes{$id}->{'d'} ne $strand);
		}
	}

	if ($currID ne $id) {
		if (exists($genes{$id})) {
			$gnames{$id}++;
			my $nid = $id . "-HOMER" . $gnames{$id};
			$genes{$nid} = $genes{$id};
		} else {
			$gnames{$id} = 1;
		}
		my @exons = ();
		my @introns = ();
		$genes{$id} = {c=>$chr,d=>$strand,v=>$score,s=>$start,e=>$end,exons=>\@exons,introns=>\@introns,n=>0,ts=>'',te=>''};
	}

	if ($feature eq 'exon' ) { #|| $feature eq 'CDS' || $feature eq '5UTR' || $feature eq '3UTR') {
		if ($genes{$id}->{'s'} > $start) {
			$genes{$id}->{'s'} = $start;
		}
		if ($genes{$id}->{'e'} < $end) {
			$genes{$id}->{'e'} = $end;
		}
		if ($mode eq 'ann' || $mode eq 'rna' || $mode eq 'exons') {
			push(@{$genes{$id}->{'exons'}},[$start,$end]);
			if ($genes{$id}->{'n'}>0) {
				push(@{$genes{$id}->{'introns'}},[$genes{$id}->{'exons'}->[$genes{$id}->{'n'}-1]->[1],$start]);
			}
			$genes{$id}->{'n'}++;
		}
	} elsif (($feature eq 'start_codon' && $strand eq '+') || ($feature eq 'stop_codon' && $strand eq '-')) {
		if ($genes{$id}->{'ts'} eq '') {
			$genes{$id}->{'ts'} = $start;
		} else {
			if ($genes{$id}->{'ts'} > $start) {
				$genes{$id}->{'ts'} = $start;
			}
		}
	} elsif (($feature eq 'stop_codon' && $strand eq '+') || ($feature eq 'start_codon' && $strand eq '-')) {
		if ($genes{$id}->{'te'} eq '') {
			$genes{$id}->{'te'} = $end;
		} else {
			if ($genes{$id}->{'te'} > $end) {
				$genes{$id}->{'te'} = $end;
			}
		}
	} elsif ($gffFlag || $gff3Flag) {
		if ($genes{$id}->{'s'} > $start) {
			$genes{$id}->{'s'} = $start;
		}
		if ($genes{$id}->{'e'} < $end) {
			$genes{$id}->{'e'} = $end;
		}
		if ($mode eq 'ann' || $mode eq 'rna' || $mode eq 'exons') {
			push(@{$genes{$id}->{'exons'}},[$start,$end]);
			if ($genes{$id}->{'n'}>0) {
				push(@{$genes{$id}->{'introns'}},[$genes{$id}->{'exons'}->[$genes{$id}->{'n'}-1]->[1],$start]);
			}
			$genes{$id}->{'n'}++;
		}
	}
	$currID = $id;
}
close IN;	


if ($mode eq 'tss' || $mode eq 'tts') {
	foreach(keys %genes) {
		my $id = $_;
		my $n = $genes{$id}->{'n'};
		next if ($n < 1 && $requireExons);
		my $start = $genes{$id}->{'s'};
		my $end = $genes{$id}->{'e'};
		my $d = $genes{$id}->{'d'};
		my $c = $genes{$id}->{'c'};
		my $score = $genes{$id}->{'v'};
		my $tss = $start;
		if ($mode eq 'tss') {
			if ($d eq '+') {
				$tss = $start;
			} elsif ($d eq '-') {
				$tss = $end;
			}
		} elsif ($mode eq 'tts') {
			if ($d eq '+') {
				$tss = $end;
			} elsif ($d eq '-') {
				$tss = $start;
			}
		}
		my $s = $tss;
		my $e = $s+$bufferSize;
		$s -= $bufferSize;
		my $printID = $id;
		$printID = $gidMapping{$id} if ($gidFlag);
		print "$printID\t$c\t$s\t$e\t$d\t$score\n";
	}
} elsif ($mode eq 'rna') {

	foreach(keys %genes) {
		my $id = $_;
		my $n = $genes{$id}->{'n'};
		next if ($n < 1 && $requireExons);
		my $start = $genes{$id}->{'s'};
		my $end = $genes{$id}->{'e'};
		my $d = $genes{$id}->{'d'};
		my $c = $genes{$id}->{'c'};
		my $ts = $genes{$id}->{'ts'};
		$ts = $start if ($ts eq '');
		my $te = $genes{$id}->{'te'};
		$te = $end if ($te eq '');
		my $printID = $id;
		$printID = $gidMapping{$id} if ($gidFlag);
		my $name = checkName($printID);
		print "$name\t$c\t$start\t$end\t$d\t";

		$n = $genes{$id}->{'n'};
		my $N = '';
		if ($d eq '+') {
			for (my $i=0;$i<$n;$i++) {
				my $comma = ",";
				$comma = "" if ($i==0);
				$N = $i+1;
				my $s = $genes{$id}->{'exons'}->[$i]->[0];
				my $e = $genes{$id}->{'exons'}->[$i]->[1];
				if ($s < $ts) {
					print $comma . "E$N" . "_5UTR:$s";
					if ($ts < $e) {
						print ",E$N:$ts";
						if ($te < $e) {
							print ",E$N" . "_3UTR:$ts";
						}
					}
				} elsif ($s < $te) {
					print $comma . "E$N:$s";
					if ($te < $e) {
						print ",E$N" . "_3UTR:$ts";
					}
				} else {
					print $comma . "E$N" . "_3UTR:$s";
				}
				if ($i < $n-1) {
					print ",I$N:$e";
				}
			}
		} elsif ($d eq '-') {
			for (my $i=0;$i<$n;$i++) {
				my $comma = ",";
				$comma = "" if ($i==0);
				$N = $n-$i;
				my $s = $genes{$id}->{'exons'}->[$i]->[0];
				my $e = $genes{$id}->{'exons'}->[$i]->[1];
				if ($s < $ts) {
					print $comma . "E$N" . "_3UTR:$s";
					if ($ts < $e) {
						print ",E$N:$ts";
						if ($te < $e) {
							print ",E$N" . "_5UTR:$ts";
						}
					}
				} elsif ($s < $te) {
					print $comma . "E$N:$s";
					if ($te < $e) {
						print ",E$N" . "_5UTR:$ts";
					}
				} else {
					print $comma . "E$N" . "_5UTR:$s";
				}
				if ($i < $n-1) {
					print ",I$N:$e";
				}
			}
		}
		
		print "\n";
	}

} elsif ($mode eq 'ann' || $mode eq 'exons') {
	foreach(keys %genes) {
		my $id = $_;
		my $n = $genes{$id}->{'n'};
		next if ($n < 1 && $requireExons);
		my $start = $genes{$id}->{'s'};
		my $end = $genes{$id}->{'e'};
		my $d = $genes{$id}->{'d'};
		my $c = $genes{$id}->{'c'};
		my $s = $start -1000;
		my $e = $start +100;
		if ($d eq '-') {
			$s = $end-100;
			$e = $end+1000;
		}
		my $printID = $id;
		$printID = $gidMapping{$id} if ($gidFlag);
		my $name = checkName("promoter-TSS ($printID)");
		print "$name\t$c\t$s\t$e\t$d\tP\n" if ($mode eq 'ann');
	}
	foreach(keys %genes) {
		my $id = $_;
		my $n = $genes{$id}->{'n'};
		next if ($n < 1 && $requireExons);
		my $start = $genes{$id}->{'s'};
		my $end = $genes{$id}->{'e'};
		my $d = $genes{$id}->{'d'};
		my $c = $genes{$id}->{'c'};
		my $s = $end -100;
		my $e = $end +1000;
		if ($d eq '-') {
			$s = $start-1000;
			$e = $start+100;
		}
		my $printID = $id;
		$printID = $gidMapping{$id} if ($gidFlag);
		my $name = checkName("TTS ($printID)");
		print "$name\t$c\t$s\t$e\t$d\tTTS\n" if ($mode eq 'ann');
	}
	foreach(keys %genes) {
		my $id = $_;
		my $n = $genes{$id}->{'n'};
		next if ($n < 1 && $requireExons);
		my $ts = $genes{$id}->{'ts'};
		my $te = $genes{$id}->{'te'};
		$ts = $genes{$id}->{'s'} if ($ts eq '');
		$te = $genes{$id}->{'e'} if ($te eq '');
		my $d = $genes{$id}->{'d'};
		my $c = $genes{$id}->{'c'};
		$n = $genes{$id}->{'n'};
		for (my $i=0;$i<$n;$i++) {
			my $N = $i+1;
			if ($d eq '-') {
				$N = $n-$i;
			}
			my $s = $genes{$id}->{'exons'}->[$i]->[0];
			my $e = $genes{$id}->{'exons'}->[$i]->[1];
			if ($ts < $s) {
				if ($te >= $e) {
					my $printID = $id;
					$printID = $gidMapping{$id} if ($gidFlag);
					my $name = checkName("exon ($printID, exon $N of $n)");
					print "$name\t$c\t$s\t$e\t$d\tE\n";
				} else {
					my $utrStart = $te+1;
					$utrStart = $s if ($te < $s);
					my $utr = "3' UTR";
					my $utrCode = "3UTR";
					if ($d eq '-') {
						$utr = "5' UTR" ;
						$utrCode = "5UTR";
					}
					my $printID = $id;
					$printID = $gidMapping{$id} if ($gidFlag);
					my $name = checkName("$utr ($printID, exon $N of $n)");
					print "$name\t$c\t$utrStart\t$e\t$d\t$utrCode\n";
					if ($te >= $s) {
						my $name = checkName("exon ($printID, exon $N of $n)");
						print "$name\t$c\t$s\t$utrStart\t$d\tE\n";
					}
				}
			} else {
				if ($ts > $s) {
					my $utrEnd = $ts-1;
					$utrEnd = $e if ($ts > $e);
					my $utr = "5' UTR";
					my $utrCode = "5UTR";
					if ($d eq '-') {
						$utr = "3' UTR";
						$utrCode = "3UTR";
					}
					my $printID = $id;
					$printID = $gidMapping{$id} if ($gidFlag);
					my $name = checkName("$utr ($printID, exon $N of $n)");
					print "$name\t$c\t$s\t$utrEnd\t$d\t$utrCode\n";
					if ($ts <= $e) {
						my $name = checkName("exon ($printID, exon $N of $n)");
						print "$name\t$c\t$ts\t$e\t$d\tE\n";
					}
				} else {
					my $printID = $id;
					$printID = $gidMapping{$id} if ($gidFlag);
					my $name = checkName("exon ($printID, exon $N of $n)");
					print "$name\t$c\t$s\t$e\t$d\tE\n";
				}
			}
		}
	}
	exit if ($mode eq 'exons');
	foreach(keys %genes) {
		my $id = $_;
		my $n = $genes{$id}->{'n'};
		next if ($n < 1 && $requireExons);
		my $ts = $genes{$id}->{'ts'};
		my $te = $genes{$id}->{'te'};
		my $d = $genes{$id}->{'d'};
		my $c = $genes{$id}->{'c'};
		$n = $genes{$id}->{'n'};
		my $tn = $n-1;
		for (my $i=0;$i<$n-1;$i++) {
			my $N = $i+1;
			if ($d eq '-') {
				$N = $n-$i-1;
			}
			my $s = $genes{$id}->{'introns'}->[$i]->[0];
			my $e = $genes{$id}->{'introns'}->[$i]->[1];
			my $printID = $id;
			$printID = $gidMapping{$id} if ($gidFlag);
			my $name = checkName("intron ($printID, intron $N of $tn)");
			print "$name\t$c\t$s\t$e\t$d\tI\n" if ($mode eq 'ann');
		}
	}
} 

sub checkName {
	my ($name) = @_;	
	if (exists($names{$name})) {
		$names{$name}++;
		return "$name-HOMER$names{$name}" if ($homerUniq);
		return "$name--$names{$name}";
	} else {
		$names{$name}=1;
		return $name;
	}
}


sub printGTF {
	my ($lines) = @_;

	my %geneIDs = ();
	my %transIDs = ();
	my $lastGeneID = '';
	my $lastTransID = '';
	my $useGeneID = '';
	my $useTransID = '';
	my $lastStrand = '';

	foreach(@$lines) {
		my $chr = $_->{'c'};
		my $col1 = $_->{'c1'};
		my $feature = $_->{'f'};
		my $start = $_->{'s'};
		my $end = $_->{'e'};
		my $score = $_->{'score'};
		my $strand = $_->{'d'};
		my $frame = $_->{'fr'};
		my $geneID = $_->{'g'};
		my $transID = $_->{'t'};

		if ($geneID ne $lastGeneID || $transID ne $lastTransID || $strand ne $lastStrand) {
			if (exists($geneIDs{$geneID})) {
				if ($homerUniq) {
					$useGeneID = $geneID . "-HOMER" . $geneIDs{$geneID}++;
				} else {
					$useGeneID = $geneID . "_" . $geneIDs{$geneID}++;
				}
			} else {
				$geneIDs{$geneID} = 2;
				$useGeneID = $geneID;
			}
			if (exists($transIDs{$transID})) {
				if ($homerUniq) {
					$useTransID = $transID . "-HOMER" . $transIDs{$transID}++;
				} else {
					$useTransID = $transID . "_" . $transIDs{$transID}++;
				}
			} else {
				$transIDs{$transID} = 2;
				$useTransID = $transID;
			}
			$lastTransID = $transID;
			$lastGeneID = $geneID;
		}
		$lastStrand = $strand;
		print "$chr\t$col1\t$feature\t$start\t$end\t$score\t$strand\t$frame\tgene_id \"$lastGeneID\"; transcript_id \"$useTransID\";\n";
	}
	close IN;
	exit;
}

sub parseAnnTable {
	my ($file) = @_;

	my %table = ();
	my %att = ();
	my $natt = 0;
	open IN, $file;
	while (<IN>) {
		chomp;
		s/\r//g;
		next if (/^#/);
		next if (/^track/);
		next if (/^browser/);
		my @line = split /\t/;
		next if (@line < 9);
		my $chr = $line[0];
		my $col1 = $line[1];
		my $feature = $line[2];
		my $start = $line[3];
		my $end = $line[4];
		my $score = $line[5];
		my $strand = $line[6];
		$strand = "+" if ($strand eq '.');
		my $frame = $line[7];
		my $gid = '';
		my $tid = "";
		my @otherAtt = ();
		if ($gffFlag) {
			$gid = $line[8];
			$tid = $line[8];
		} else {
			my @attributes = split /\;/,$line[8];
			foreach(@attributes) {
				s/^\s*//;
				my @pair = ();
				if ($gff3Flag || $gffFlag) {
					@pair = split /=/,$_;
				} else {
					@pair = split / /,$_;
				}

				next if (@pair < 2);
				$pair[1] =~ s/\"//g;
				if ($pair[0] eq 'gene_id') {
					$gid = $pair[1];
				} elsif ($pair[0] eq 'transcript_id') {
					$tid = $pair[1];
				} elsif ($gff3Flag && $pair[0] eq 'Parent') {
					$gid = $pair[1];
					$tid = $pair[1];
				} else {
					push(@otherAtt, \@pair);
				}
			}
		}
		my $id = $gid;
		$id = $tid if ($gidFlag == 0);
		if ($removeAccFlag == 1) {
			$id =~ s/\.\d+$//;
		}
		if (!exists($table{$id})) {
			my %a = ();
			$table{$id} = \%a;
		}
		foreach(@otherAtt) {
			$table{$id}->{$_->[0]} = $_->[1];
			if (!exists($att{$_->[0]})) {
				$att{$_->[0]} = $natt++;
			}
		}
	}
	my @att = sort {$att{$a} <=> $att{$b}} keys %att;
	print "Accession";
	foreach(@att) {
		print "\t$_";
	}
	print "\n";
	my @id = keys %table;
	foreach(@id) {
		my $id = $_;
		print "$id";
		foreach(@att) {
			if (exists($table{$id}->{$_})) {
				print "\t$table{$id}->{$_}";
			} else {
				print "\t";
			}
		}
		print "\n";
	}
}

