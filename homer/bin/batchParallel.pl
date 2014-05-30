#!/usr/bin/env perl
use warnings;



my $maxCPUs = 12;
if (@ARGV < 2) {
	print STDERR "\n\tUsage: batchParallel.pl <command> <output suffix|none> [options] -f <file1> <file2>...\n";
	print STDERR "\n\tThis will run the <command> for each file provided after the -f parameter.\n";
	print STDERR "\n\tOptions:\n";
	print STDERR "\t\t-cpu <#> (max number of parallel processes, default: $maxCPUs)\n";
	print STDERR "\t\tAll other parameters up to '-f' will be based to the command\n";
	print STDERR "\n\tExample (gzip fastq files): batchParallel.pl gzip none -f *.fastq\n";
	print STDERR "\tExample (bed to peak format): batchParallel.pl bed2pos.pl pos -f *.bed\n";
	print STDERR "\tExample (finding peaks): batchParallel.pl findPeaks none -o auto -style factor -f */\n";
	print STDERR "\n\tSimilar to batchApply.pl (non-parallel version)\n";
	print STDERR "\n";
	exit;
}

my $cmd = $ARGV[0];
my $suffix = $ARGV[1];

my $opt = "";
my $flag = 0;
my @files = ();
for (my $i=2;$i<@ARGV;$i++) {
	if ($ARGV[$i] eq '-cpu') {
		$maxCPUs = $ARGV[++$i];
		next;
	}
	if ($ARGV[$i] eq '-f') {
		$flag = 1;
		next;
	}
	if ($flag) {
		push(@files, $ARGV[$i]);
	} else {
		$opt .= ' ' . $ARGV[$i];
	}
}
print STDERR "@files\n";

my @pids = ();
my $cpus = 0;
foreach(@files) {
	my $pid = fork();
	$cpus++;
	if ($pid == 0) {
		#child process
		if ($suffix eq 'none') {
			print STDERR "=========\n$cmd $_ $opt\n";
			`$cmd $_ $opt`;
		} else {
			print STDERR "=========\n$cmd $_ $opt > $_.$suffix\n";
			`$cmd $_ $opt > $_.$suffix`;
		}
		exit(0);
	}
	push(@pids, $pid);
	if ($cpus >= $maxCPUs) {
		my $id = wait();
		print "\t$id finished\n";
		$cpus--;
	}
}
my $id = 0;
while ($id >= 0) {
	$id = wait();
	if ($id == -1) {
		print STDERR "\tALL FINISHED!!!\n";
	} else {
		print STDERR "\t$id finished\n";
	}
}
print STDERR "\n";

