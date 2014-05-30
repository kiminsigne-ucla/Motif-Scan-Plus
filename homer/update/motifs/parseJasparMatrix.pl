#!/usr/bin/perl -w
open IN, $ARGV[0];
my @data = ();
while (<IN>) {
	chomp;
	if (/^>/) {
		s/^>//;
		s/ /_/g;
		push(@data, $_);
	} else {
		s/^.+\[\s*//;
		s/\s*\].*$//;
		my @d = split /\s+/;
		push(@data, \@d);
	}
}
close IN;


for (my $i=0;$i<@data;$i+=5) {
	my $name= $data[$i+0];
	next if ($name =~ /^CN/);
	next if ($name =~ /^PF/);
	print ">$name\t$name/Jaspar\t0\n";
	my $len = scalar(@{$data[$i+1]});
	for (my $j=0;$j<$len;$j++) {
		my $v = $data[$i+1][$j];
		print "$v";
		for (my $k=1;$k<4;$k++) {
			my $vv = $data[$i+1+$k][$j];
			print "\t$vv";
		}
		print "\n";
	}
}
