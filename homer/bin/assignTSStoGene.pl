#!/usr/bin/env perl
use warnings;
use lib "/home/kimberly/Motif-Scan-Plus/homer/.//bin";
my $homeDir = "/home/kimberly/Motif-Scan-Plus/homer/./";


# Copyright 2009-2014 Christopher Benner <cbenner@salk.edu>
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

use POSIX;
use HomerConfig;

my $config = HomerConfig::loadConfigFile();

my $maxDistance = 1000;

sub printCMD {

	print STDERR "\n\tUsage: assignTSStoGene.pl <tss peak file> [options]\n";
	print STDERR "\n\tThis program takes TSS defined by 5' RNA sequencing and assigns them to genes\n";
	print STDERR "\n\tOne of the following options are required to define genes:\n";
	print STDERR "\t\t-genome <genomeVersion> (use default homer gene annotation/RefSeq)\n";
	print STDERR "\t\t-gtf <GTF file> (use custom gene annotation, can also use -gff or -gff3)\n";
	print STDERR "\t\t-refTSS <tss peak file> (peak file of reference TSS positions)\n";
	print STDERR "\n\tOther Options:\n";
	print STDERR "\t\t-d <#> (max dist from tss to gene allowed, default: $maxDistance)\n";
	print STDERR "\t\t-nokeepRef (don't keep reference promoters not found in the tss peak file, default: keep)\n";
	print STDERR "\t\t-keepOrphans (keep TSS without reference annotation, default: remove)\n";
	print STDERR "\n";
	exit;

}

if (@ARGV < 3) { 
	printCMD();
}

my $cmd = $ARGV[0];
for (my $i=1;$i<@ARGV;$i++) {
	$cmd .= " " . $ARGV[$i];
}

print STDERR "\n";
my %toDelete = ();

my $gtfFile = "";
my $gtfFormat = "";
my $oldTSSfile = "";
my $genome = "";

my $organism = "unknown";
my $promoter = "default";
my $consDir = "";
my $genomeDir = "";
my $genomeParseDir = "";
my $customGenome = 0;
my $keepRef = 1;
my $keepOrphans = 0;

my $tssFile = $ARGV[0];

for (my $i=1;$i<@ARGV;$i++) {
	if ($ARGV[$i] eq '-genome') {
		$genome  = $ARGV[++$i];
	} elsif ($ARGV[$i] eq '-nokeepRef') {
		$keepRef = 0;
	} elsif ($ARGV[$i] eq '-keepOrphans') {
		$keepOrphans = 1;
	} elsif ($ARGV[$i] eq '-gtf') {
		$gtfFile = $ARGV[++$i];
	} elsif ($ARGV[$i] eq '-gff') {
		$gtfFile = $ARGV[++$i];
		$gtfFormat = "-gff";
	} elsif ($ARGV[$i] eq '-gff3') {
		$gtfFile = $ARGV[++$i];
		$gtfFormat = "-gff3";
	} elsif ($ARGV[$i] eq '-refTSS') {
		$oldTSSfile = $ARGV[++$i];
	} elsif ($ARGV[$i] eq '-d') {
		$maxDistance = $ARGV[++$i];
	} else {
		print STDERR "Not recognized: $ARGV[$i]\n";
		printCMD();
	}
}


if ($genome eq "" && $gtfFile eq "" && $oldTSSfile eq '') {
	print STDERR "!!! Missing -genome/-gtf/-refTSS !!!\n";
	printCMD();
}


if ($genome ne '') {
	if ($genome eq 'none') {
		print STDERR "!!! Can't specify -genome none for this command !!!\n";
		printCMD();
	} elsif (!exists($config->{'GENOMES'}->{$genome})) {
		print STDERR "!!! Genome not recognized - that's a problem for this command !!!\n";
		printCMD();
	} else {
		$genomeDir = $config->{'GENOMES'}->{$genome}->{'directory'};	
		$organism = $config->{'GENOMES'}->{$genome}->{'org'};	
		$promoter = $config->{'GENOMES'}->{$genome}->{'promoters'};
		$consDir = $config->{'GENOMES'}->{$genome}->{'directory'} . "/conservation/";
		if ($oldTSSfile eq '') {
			$oldTSSfile = $genomeDir . "/" . $genome . ".tss";
		}
	}
	print STDERR "\tGenome = $genome\n";
	print STDERR "\tOrganism = $organism\n";
}

my $rand = rand();
my $tmpFile = $rand . ".tmp";
my $tmpFile2 = $rand . ".2.tmp";

if ($gtfFile ne '') {
	if ($oldTSSfile eq '') {
		`parseGTF.pl "$gtfFile" tss $gtfFormat > "$tmpFile"`;
	} else {
		`cp "$oldTSSfile" "$tmpFile"`;
	}
} elsif ($oldTSSfile eq '') {
	my $refSeqTSS = "$genomeDir/$genome.tss";
	`cp "$refSeqTSS" "$tmpFile"`;
} else {
	`cp "$oldTSSfile" "$tmpFile"`;
}		
$toDelete{$tmpFile} = 1;
$toDelete{$tmpFile2} = 1;

my %tss = ();
open IN, $tssFile;
while (<IN>) {
	chomp;
	s/\r//g;
	my @line = split /\t/;
	my $id = $line[0];
	my $chr=  $line[1];
	my $start = $line[2];
	my $end = $line[3];
	my $strand = $line[4];
	my $v = $line[5];
	$tss{$id} = {c=>$chr,s=>$start,e=>$end,d=>$strand,v=>$v};
}
close IN;

`annotateRelativePosition.pl "$tssFile", "$tmpFile", 1 > "$tmpFile2"`;
open IN, "$tmpFile2";
my %genes = ();
while (<IN>) {
	chomp;
	s/\r//g;
	my @line = split /\t/;
	my $tssID =$line[0];
	my $gid =$line[1];
	my $dist = $line[2];
	if (abs($dist) > $maxDistance) {
		next;
	}
	my $d ={id=>$tssID,dist=>$dist};
	if (!exists($genes{$gid})) {
		$genes{$gid} = $d;
	} else {
		if ($tss{$tssID}->{'v'} > $tss{$genes{$gid}->{'id'}}->{'v'}) {
			$genes{$gid} = $d;
		} elsif ($tss{$tssID}->{'v'} == $tss{$genes{$gid}->{'id'}}->{'v'}
				&& abs($dist) < abs($genes{$gid}->{'dist'})) {
			$genes{$gid} = $d;
		}
	}
}
close IN;

my %printedTSS = ();
open IN, $tmpFile;
while (<IN>){
	chomp;
	s/\r//g;
	next if (/^#/);
	my $og = $_;
	my @line = split /\t/;

	if (exists($genes{$line[0]})) {
		my $tssID = $genes{$line[0]}->{'id'};
		$printedTSS{$tssID} = 1;
		print "$line[0]\t$tss{$tssID}->{'c'}\t$tss{$tssID}->{'s'}\t$tss{$tssID}->{'e'}\t$tss{$tssID}->{'d'}\t$tss{$tssID}->{'v'}\n";
	} elsif ($keepRef) {
		print "$og\n";
	}
}
close IN;
if ($keepOrphans) {
	foreach(keys %tss) {
		next if (exists($printedTSS{$_}));
		my $tssID = $_;
		print "$tssID\t$tss{$tssID}->{'c'}\t$tss{$tssID}->{'s'}\t$tss{$tssID}->{'e'}\t$tss{$tssID}->{'d'}$tss{$tssID}->{'v'}\n";
	}
}

deleteFiles();

sub deleteFiles {
	foreach(keys %toDelete) {
		`rm "$_"`;
	}
}
