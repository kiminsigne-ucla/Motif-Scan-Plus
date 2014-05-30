#!/usr/bin/env perl
use warnings;




use POSIX;

# Copyright 2009 - 2014 Christopher Benner <cbenner@salk.edu>
# 
# This file is part of HOMER
#
# HOMER is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# HOMER is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.



sub printCMD() {
	print STDERR "\n\tadjustPeakFile.pl <peak/position file> [options]\n";
	print STDERR "\n\tOptions:\n";
	print STDERR "\t\t-size <#> (resize peak [around center] to this size, supports -size <#,#>)\n";
	print STDERR "\t\t-rsize <#> (resize peak by this relative size, supports -size <#,#>)\n";
	print STDERR "\t\t-move <#> (move peak [relative to strand], default: 0)\n";
	print STDERR "\t\t-5p (recenter peak on 5' end of region)\n";
	print STDERR "\t\t-3p (recenter peak on 3' end of region)\n";
	print STDERR "\t\t-flipStrand (change strand of peak)\n";
	print STDERR "\n";
	exit;
}


my $size = 'given';
my $move = 0;
my $rStart = 0;
my $rEnd = 0;
my $headerFlag = 0;
my $flipStrand = 0;

if (@ARGV < 1) {
	printCMD();
}
my $peakFile = $ARGV[0];


for (my $i=1;$i<@ARGV;$i++){ 
	if ($ARGV[$i] eq '-size') {
	    $size = $ARGV[++$i];
        if ($size eq 'given') {
            print STDERR "\tUsing actual sizes of regions\n";
        } elsif ($size =~ /\,/) {
            my @a = split /\,/, $size;
            my $sizeStart= $a[0];
            my $sizeEnd = $a[1];
            if ($sizeEnd < $sizeStart) {
                print STDERR "!!! Size end must be less than the size start range in -size $sizeStart,$sizeEnd\n";
                exit;
            }
            $move = floor(($sizeStart+$sizeEnd)/2);
            $size = $sizeEnd - $sizeStart;
        }
	} elsif ($ARGV[$i] eq '-rsize') {
	    my $rsize = $ARGV[++$i];
        if ($rsize eq 'given') {
            print STDERR "\tUsing actual sizes of regions\n";
        } elsif ($rsize =~ /\,/) {
            my @a = split /\,/, $rsize;
            $rStart= $a[0];
            $rEnd = $a[1];
        } else {
			$rStart = $rsize/2;
			$rEnd = $rsize/2;
		}
	} elsif ($ARGV[$i] eq '-move') {
		$move = $ARGV[++$i];
	} elsif ($ARGV[$i] eq '-flipStrand') {
		$flipStrand = 1;
	} elsif ($ARGV[$i] eq '-5p') {
		$p5Flag = 1;
	} elsif ($ARGV[$i] eq '-3p') {
		$p3Flag = 1;
	} else {
		printCMD();
	}
}


my $half = 'given';
if ($size ne 'given') {
	$half = $size/2;
}

my $removed = 0;	

open IN, $ARGV[0];
my $count = 0;
while (<IN>) {
	$count++;
	chomp;
	s/\r//g;
	next if (/^#/);
	if ($count == 1 && $headerFlag) {
		print "$_\n";
		next;
	}
	my @line = split /\t/;

	next if (@line < 5);
	if (!($line[2] =~ /^\d+$/)) {
		next;
	}
	foreach(@line) {
		s/^\s*//;
		s/\s*$//;
	}

	my $id = $line[0];
	my $chr = $line[1];
	my $s = $line[2];
	my $e = $line[3];
	my $strand = $line[4];

	if ($p5Flag) {
		my $len =floor(($e-$s)/2);
		my $p = $s;
		if ($strand eq '-' || $strand eq '1') {
			$p = $e;
		}
		$s = $p-$len;
		$e = $p+$len;
	}
	if ($p3Flag) {
		my $len =floor(($e-$s)/2);
		my $p = $e;
		if ($strand eq '-' || $strand eq '1') {
			$p = $s;
		}
		$s = $p-$len;
		$e = $p+$len;
	}


	if ($strand eq '-' || $strand eq '1') {
		$s -= $move;
		$e -= $move;
	} else {
		$s += $move;
		$e += $move;
	}

	if ($size ne 'given') {
		my $center = (($s+$e)/2);
		$s = floor($center - $half);
		$e = floor($center + $half);
	}
	$s += $rStart;
	$e += $rEnd;
	if ($e < $s) {
		$removed++;
		next;
	}
	if ($flipStrand > 0) {
		if ($strand eq '0' || $strand eq '+') {
			$strand = '-';
		} else {
			$strand = '+';
		}
	}

	print "$line[0]\t$line[1]\t$s\t$e\t$strand";
	for (my $i=5;$i<@line;$i++) {
		print "\t$line[$i]";
	}
	print "\n";
}
close IN;


if ($removed > 0) {
	print STDERR " $removed peaks removed because there size was less than 0\n";
}
