#!/usr/bin/env perl
use warnings;
use lib "/home/kimberly/Motif-Scan-Plus/homer/.//bin";
my $homeDir = "/home/kimberly/Motif-Scan-Plus/homer/./";


use POSIX;
use HomerConfig;


my $suffix = ".masked";
my $suffix2 = ".fa";

my $config = HomerConfig::loadConfigFile();

if (@ARGV < 2) {
	print STDERR "\n\tUsage: scanMotifGenomeWide.pl <motif> <genome> [-5p] [-homer1/2] [-bed] [-keepAll] [-mask]\n";
	print STDERR "\t\tPossible Genomes:\n";
	foreach(keys %{$config->{'GENOMES'}}) {
		print STDERR "\t\t$_\t$config->{'GENOMES'}->{$_}->{'org'}\t$config->{'GENOMES'}->{$_}->{'directory'}\n";
	}
	print STDERR "\t\t\t-- or --\n";
    print STDERR "\t\tCustom: provide the path to genome FASTA files (directory or single file)\n";
	print STDERR "\n\tOutput will be sent to stdout\n";
	print STDERR "\tAdd -5p to report positions centered on the 5' start of the motif\n";
	print STDERR "\tAdd -bed to format as a BED file (i.e. for UCSC upload)\n";
	print STDERR "\tAdd -homer1 to use the original homer\n";
	print STDERR "\tAdd -homer2 to use homer2 instead of the original homer(default)\n";
	print STDERR "\tAdd -keepAll to keep ALL sites, even ones that overlap (default - keep one)\n";
	print STDERR "\tAdd -mask to search for motifs in repeat masked sequence.\n";
	print STDERR "\n";
	exit;
}

my $p5flag = 0;
my $maskFlag = 0;
$homer2Flag = 1;
my $bedFlag = 0;
my $keepAllFlag = 0;
for (my $i=2;$i<@ARGV;$i++) {
	if ($ARGV[$i] eq '-5p') {
		$p5flag = 1;
		print STDERR "Outputing file centered on the 5' start of the motif\n";
	} elsif ($ARGV[$i] eq '-bed') {
		$bedFlag = 1;
	} elsif ($ARGV[$i] eq '-mask') {
		$maskFlag = 1;
	} elsif ($ARGV[$i] eq '-keepAll') {
		$keepAllFlag = 1;
	} elsif ($ARGV[$i] eq '-homer1') {
		$homer2Flag = 0;
		print STDERR "\tUsing original homer to scan for motifs\n";
	} elsif ($ARGV[$i] eq '-homer2') {
		$homer2Flag = 1;
		print STDERR "\tUsing homer2 to scan for motifs\n";
	}
}


my $mfile = $ARGV[0];

my $genome = $ARGV[1];
my $genomeDir = "";
my $customGenome = 0;
if (!exists($config->{'GENOMES'}->{$genome})) {
	$customGenome = 1;
	my $asdf = "";
	($genome,$genomeDir,$asdf) = HomerConfig::parseCustomGenome($genome);
} else {
	$genomeDir = $config->{'GENOMES'}->{$genome}->{'directory'};
}


my $size = 10000;

my $tmpFile = rand() . ".tmp";
my $tmpFile2 = $tmpFile . ".2";

if ($customGenome==1 && -f $genomeDir) {
	`ls -1 "$genomeDir" > "$tmpFile"`;
} else {
	`ls -1 "$genomeDir"/*fa* > "$tmpFile"`;
}
open IN, $tmpFile;
my @files = ();
while (<IN>) {
	chomp;
	s/\r//g;
	push(@files, $_);
}
close IN;

my %idCounts = ();

foreach(@files) {
	my $file = $_;
#$file =~ s/(\/.*)?$//;
#$file .= "/bioinformatics/homer/data/genomes/mm9/chr11.fa";
	open IN, $file or die "Couldn't open $file\n";
	my $position = 0;
	my $totalLength = 0;
	my $chr = '';
	my $curSeq = '';
	my $startPos = 0;
	my $justPrinted = 0;

	open SEQFILE, ">$tmpFile2";

	while (<IN>) {
		chomp;
		s/\r//g;
		if (/^>/) {
			/^>(.*?)$/;
			$chr = $1;
			print STDERR "\n\tProcessing $chr\n";
			$position = 0;
			$totalLength = 0;
			$curSeq = '';
			$startPos = 0;
			next;
		}
		if ($maskFlag==1) {
			s/[acgt]/N/g;
		} else {
			s/a/A/g;
			s/c/C/g;
			s/g/G/g;
			s/t/T/g;
		}

		my $len = length($_);
		$totalLength += $len;
		$curSeq .= $_;
		if ($totalLength > $size) {
			print SEQFILE "$chr-$startPos\t$curSeq\n";		
			$totalLength = $len;
			$startPos = $position;
			$curSeq = $_;
			$justPrinted = 1;
		} else {
			$justPrinted = 0;
		}

		$position += $len;

	}
	if ($justPrinted == 0) {
		print SEQFILE "$chr-$startPos\t$curSeq\n";		
	}
	close IN;
	close SEQFILE;

	if ($homer2Flag) {
		`homer2 find -s "$tmpFile2" -m "$mfile" -offset 0 > "$tmpFile"`;
	} else {
		`homer -s "$tmpFile2" -a FIND -m "$mfile" > "$tmpFile"`;
	}

	open IN, "$tmpFile";
	my %pos = ();
	my @sites = ();
	while (<IN>) {
		chomp;
		my @line = split /\t/;

		$line[0]=~ /^(.*?)\-(\d+)$/;
		my $chr = $1;
		my $gpos = $2;
		my $pos = $line[1];
		my $seq = $line[2];

		my $d = 0;
		my $name = "";
		my $score = "";
		if ($homer2Flag) {
			$name = $line[3];
			$d = $line[4];
			$score = $line[5];
		} else {
			$d = $line[4];
			$name = $line[5];
			$score = $line[6];
		}

		my $start = $gpos+$pos+1;
		my $end = $start + length($seq)-1;
		if ($homer2Flag && ($d eq '-' || $d eq '1') ) {
			$start -= length($seq)-1;
			$end -= length($seq)-1;
		}
		my $mid = floor(($start+$end)/2);

		my $pd = $name . "-" . $chr . "-" . $start . "-" . $d;
		next if (exists($pos{$pd}));
		$pos{$pd}= 1;

		if (!exists($idCounts{$name})) {
			$idCounts{$name} = 1;
		}

		if ($p5flag==1) {
			my $center = $start;
			if ($d eq '-' || $d eq '1') {
				$center = $end;
			}
			$start = $center -100;
			$end = $center +100;
		}

		my $ss = {s=>$start,e=>$end,d=>$d,seq=>$seq,m=>$mid,n=>$name,ss=>$score,c=>$chr};
		push(@sites, $ss);
	}
	close IN;
	@sites = sort {$a->{'m'} <=> $b->{'m'}} @sites;

	my $Nsites = scalar(@sites);
	my $removed= 0;

	for (my $i=0;$i<@sites;$i++) {
		my $m= $sites[$i]->{'m'};
		my $bad = 0;
		my $mlen = length($sites[$i]->{'seq'});
		if ($keepAllFlag==0) {
			for (my $j=$i-1;$j>=0;$j--) {
				last if ($m - $sites[$j]->{'m'} > $mlen/2);
				if ($sites[$i]->{'n'} eq $sites[$j]->{'n'} && 
						$sites[$i]->{'c'} eq $sites[$j]->{'c'} && 
							$sites[$i]->{'ss'} < $sites[$j]->{'ss'}) {
					$bad = 1;
					last;
				}
			}
			for (my $j=$i+1;$j<@sites;$j++) {
				last if ($sites[$j]->{'m'}-$m > $mlen/2);
				if ($sites[$i]->{'n'} eq $sites[$j]->{'n'} &&
						$sites[$i]->{'c'} eq $sites[$j]->{'c'} && 
							$sites[$i]->{'ss'} <= $sites[$j]->{'ss'}) {
					$bad = 1;
					last;
				}
			}
		}
		if ($bad == 0) {
			if ($bedFlag) {
				my $name = $sites[$i]->{'n'};
				$name =~ s/-ChIP-Seq\/Homer//g;
				$name =~ s/\/Homer//g;
				print "$sites[$i]->{'c'}\t$sites[$i]->{'s'}\t$sites[$i]->{'e'}\t$name\t$sites[$i]->{'ss'}\t$sites[$i]->{'d'}\n";
			} else {
				my $id = $idCounts{$sites[$i]->{'n'}};
				print "$sites[$i]->{'n'}-$id\t$sites[$i]->{'c'}\t$sites[$i]->{'s'}\t$sites[$i]->{'e'}\t$sites[$i]->{'d'}"
										. "\t$sites[$i]->{'ss'}\t$sites[$i]->{'seq'}\n";
				$idCounts{$sites[$i]->{'n'}}++;
			}
		} else {
			$removed++;
		}
	}
	print STDERR "\t$chr - $Nsites ($removed)\n";
}

`rm -f "$tmpFile" "$tmpFile2"`;
