#!/usr/bin/env perl
use warnings;



my $program = "liftOver";

if (@ARGV < 3 ){ 
	printCMD();
}

sub printCMD {
	print STDERR "\n\tUsage: convertCoordinates.pl <liftOver.over.chain file> <input file/directory> <output file/directory> [options]\n";
	print STDERR "\n\tOptions:\n";
	print STDERR "\t\t-type <directory|peaks|tags|bed> (input is a tag directory, peak file, tags file, or BED)\n";
	print STDERR "\t\t-p <#> (Number of CPUs to use, default: 1)\n";
	print STDERR "\t\t-minMatch <#> (minimum % of nucleotides that must match, default: 0.1)\n";
	print STDERR "\n\tShorthand options for type:\n";
	print STDERR "\t\t-directory (input is a tag directory, default)\n";
	print STDERR "\t\t-peaks (input is a peak file)\n";
	print STDERR "\t\t-tags (input is a tag file)\n";
	print STDERR "\t\t-bed (input is a bed file)\n";
	print STDERR "\n";
	exit;
}

my $peakFlag = 0;
my $dirFlag = 1;
my $bedFlag = 0;
my $minMatch = 0.1;
my $minBlocks = 0.1;
my $maxCPUs = 1;

for (my $i=3;$i<@ARGV;$i++) {
	if ($ARGV[$i] eq '-peaks') {
		$peakFlag = 1;
		$dirFlag = 0;
	} elsif ($ARGV[$i] eq '-dir' || $ARGV[$i] eq '-directory') {
		$dirFlag = 1;
		$peakFlag = 0;
	} elsif ($ARGV[$i] eq '-tags') {
		$dirFlag = 0;
		$peakFlag = 0;
	} elsif ($ARGV[$i] eq '-bed') {
		$dirFlag = 0;
		$peakFlag = 0;
		$bedFlag = 1;
	} elsif ($ARGV[$i] eq '-type') {
		$i++;
		if ($ARGV[$i] eq 'peaks') {
			$peakFlag = 1;
			$dirFlag = 0;
		} elsif ($ARGV[$i] eq 'dir' || $ARGV[$i] eq 'directory') {
			$dirFlag = 1;
			$peakFlag = 0;
		} elsif ($ARGV[$i] eq 'tags') {
			$dirFlag = 0;
			$peakFlag = 0;
		} elsif ($ARGV[$i] eq 'bed') {
			$dirFlag = 0;
			$peakFlag = 0;
			$bedFlag = 1;
		} else {
			print STDERR "!!! Error, unknown type: $ARGV[$i]\n";
			exit;
		}
	} elsif ($ARGV[$i] eq '-minMatch') {
		$minMatch = $ARGV[++$i];
	} elsif ($ARGV[$i] eq '-p') {
		$maxCPUs = $ARGV[++$i];
	} else {
		print STDERR "!!! Unknown option: $ARGV[$i]\n";
		printCMD();
	}
}

my $check = `which liftOver`;
if ($check eq '') {
	print STDERR "\t\t-program <liftOver program location> (if not in executable path)\n";
	print STDERR "\n\tTo use this program, the liftOver tool from UCSC must be installed\n";
	print STDERR "\tand in the executable path (or use -program ...).\n";
	print STDERR "\n\tDownload the liftOver tool from:\n";
	print STDERR "\t\thttp://hgdownload.cse.ucsc.edu/admin/exe/\n";
	print STDERR "\n\n";
	exit;
}
if (@ARGV < 3) {
	print STDERR "\n";
	exit;
}

#$program = "/bioinformatics/software/liftover/liftOver";
my $rand = rand();
my $tmpfile = $rand . ".tmp";
my $tmpfile2 = $rand . ".2.tmp";
my $tmpfile3 = $rand . ".3.tmp";
if ($peakFlag == 1) {
	`pos2bed.pl "$ARGV[1]" > "$tmpfile"`;
} elsif ($dirFlag == 1) {
	`cat "$ARGV[1]"/*.tags.tsv > "$tmpfile2"`;
	`tag2bed.pl "$tmpfile2"  > "$tmpfile"`;
} elsif ($bedFlag) {
	`cp "$ARGV[1]" "$tmpfile"`;
} else {
	`tag2bed.pl "$ARGV[1]" > "$tmpfile"`;
}
if ($maxCPUs < 2) {
	`"$program" -minMatch=$minMatch -minBlocks=$minBlocks "$tmpfile" "$ARGV[0]" "$tmpfile2" "$tmpfile3"`;
} else {
	my @fileNames = ();
	my @files = ();

	my $cat1 = '';
	my $cat2 = '';
	my $cat3 = '';
	for (my $i=0;$i<$maxCPUs;$i++) {
		my $handle;
		my $fname = "$rand.cpu.$i.tmp";
		push(@fileNames, $fname);
		$cat1 .= " \"$fname\"";
		$cat2 .= " \"$fname.2\"";
		$cat3 .= " \"$fname.3\"";
		open($handle, ">$fname");
		push(@files, $handle);
	}
	open IN, $tmpfile;
	my $c = 0;
	while (<IN>) {
		if ($c >= $maxCPUs) {
			$c = 0;
		}
		#print($files[$c++],$_);
		my $h = $files[$c++];
		print $h $_;
	}
	close IN;

	foreach(@files) {
		close $_;
	}

	for (my $i=0;$i<$maxCPUs;$i++) {
		my $pid= fork();
		my $fname = $fileNames[$i];
		if ($pid == 0) {	
			`"$program" -minMatch=$minMatch -minBlocks=$minBlocks "$fname" "$ARGV[0]" "$fname.2" "$fname.3"`;
			exit(0);
		}
	}
	my $id = 0;
	while ($id >= 0) {
		$id = wait();
	}
	`cat $cat2 > "$tmpfile2"`;
	`cat $cat3 > "$tmpfile3"`;
	`rm $cat2 $cat3 $cat1`;
}

if ($peakFlag) {
	`bed2pos.pl "$tmpfile2" > "$ARGV[2]"`;
} elsif ($dirFlag==1) {
	`makeTagDirectory "$ARGV[2]" "$tmpfile2" -format bed  -force5th`;
} elsif ($bedFlag) {
	`cp "$tmpfile2" "$ARGV[2]"`;
} else {
	`bed2tag.pl "$tmpfile2" > "$ARGV[2]"`;
}
`rm "$tmpfile" "$tmpfile2" "$tmpfile3"`;

