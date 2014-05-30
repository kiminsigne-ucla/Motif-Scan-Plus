#!/usr/bin/env perl
use warnings;
use lib "/home/kimberly/Motif-Scan-Plus/homer/.//bin";
my $homeDir = "/home/kimberly/Motif-Scan-Plus/homer/./";
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

use HomerConfig;

my $config = HomerConfig::loadConfigFile();

my $destGO = "../data/GO/";
my $destAcc = "../data/accession/";

my $preUniprot = 0;

sub printCMD {
	print STDERR "\n\tUpdating Gene Identifier conversion table...\n";
	print STDERR "\tUsage: ./updateGeneIdentifiers.pl <taxid.tsv> [additional ID convertion files]...\n";
	print STDERR "\n\tusually include externalIDs.txt\n";
	print STDERR "\n\tOther Tasks for update:\n";
	print STDERR "\t\tRedownload msigdb.v2.5.symbols.gmt from GSEA and rename to msigdb.gmt\n";
	print STDERR "\tThis program should be run from the 'update' directory\n";
	print STDERR "\tOutput will be sent to:\n";
	print STDERR "\t\t$destGO/\n";
	print STDERR "\t\t$destAcc/\n";
	print STDERR "\n\tIf a copy of the file uniprot_trembl.dat or uniprot_trembl.dat.gz is present,\n";
	print STDERR "\tthe program will use it instead of downloading it again (can take a while...)\n";
	print STDERR "\n\n";
}
if (@ARGV < 1) {
	printCMD();
	exit;
}
print STDERR "\n\tReminder: Download the msigdb (all) symbols file into the update directory and rename it msigdb.gmt\n";
my $taxidFile = $ARGV[0];

if ($preUniprot) {
	print STDERR "\t!! Assuming Uniprot should already be downloaded...\n";
}

print STDERR "\n\tOrganism\tTaxID\tFullName\tVersion\tExisting Version\n";
my %orgInfo = ();
my %orgs = ();
open IN, $taxidFile;
while (<IN>) {
	chomp;
	my @line = split /\t/;
	next if ($line[0] eq 'Taxid');
	next if (/^#/);
	$orgs{$line[1]} = $line[0];
	$orgInfo{$line[1]} = {taxid=>$line[0],fullName=>$line[2],version=>$line[3]};
	print STDERR "\t$line[1]\t$line[0]\t$line[2]\t$line[3]\t";
	if (exists($config->{'ORGANISMS'}->{$line[1]})) {
		print STDERR $config->{'ORGANISMS'}->{$line[1]}->{'version'};
	} else {
		print STDERR "Not installed";
	}
	print STDERR "\n";
}
close IN;

print STDERR "\n\tWating 10 seconds in case you want to review the changes (hit ctrl+C to cancel)\n";
for (my $i=10;$i>0;$i--) {
	print "\t\t$i\n";
	`sleep 1`;
}

my $addFiles = '';
for (my $i=1;$i<@ARGV;$i++){ 
	next if ($ARGV[$i] eq 'null');
	$addFiles .= " $ARGV[$i]";
}
print STDERR "Addfiles = $addFiles\n";

#remove existing files
if (1) {
	print STDERR "\tRemoving existing data/annotation source files...\n";
	`rm gene2accession`;
	`rm gene2unigene`;
	`rm gene_info`;
	`rm gene2refseq`;
	`rm gene2ensembl`;
	`rm gene2go`;
	`rm gene_history`;
	`rm gene_ontology_edit.obo`;
	`rm uniprot_sprot.dat`;
	`rm interactions`;
}

# gene database downloads
if (1) {
	print STDERR "\tDownloading data/annotation source files...\n";
	`wget -O gene2accession.gz ftp://ftp.ncbi.nih.gov/gene/DATA/gene2accession.gz`;
	`wget -O gene2unigene ftp://ftp.ncbi.nih.gov/gene/DATA/gene2unigene`;
	`wget -O gene_info.gz ftp://ftp.ncbi.nih.gov/gene/DATA/gene_info.gz`;
	`wget -O gene2refseq.gz ftp://ftp.ncbi.nih.gov/gene/DATA/gene2refseq.gz`;
	`wget -O gene2ensembl.gz ftp://ftp.ncbi.nih.gov/gene/DATA/gene2ensembl.gz`;
	`wget -O gene2go.gz ftp://ftp.ncbi.nih.gov/gene/DATA/gene2go.gz`;
	`wget -O gene_history.gz ftp://ftp.ncbi.nih.gov/gene/DATA/gene_history.gz`;
	`wget -O gene_ontology_edit.obo http://www.geneontology.org/ontology/gene_ontology_edit.obo`;
	`wget -O uniprot_sprot.dat.gz ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.dat.gz`;
	if (-e "uniprot_trembl.dat" || -e "uniprot_trembl.dat.gz") {
	} else {
		`wget -O uniprot_trembl.dat.gz ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_trembl.dat.gz`;
	}
	`wget -O interactions.gz ftp://ftp.ncbi.nih.gov/gene/GeneRIF/interactions.gz`;
	`wget -O homologene.data ftp://ftp.ncbi.nih.gov/pub/HomoloGene/current/homologene.data`;
	`cp homologene.data ../data/accession/`;

	print STDERR "\tUnzipping downloaded files...\n";
	`gunzip -f gene2accession.gz`;
	`gunzip -f gene_info.gz`;
	`gunzip -f gene2refseq.gz`;
	`gunzip -f gene2ensembl.gz`;
	`gunzip -f gene_history.gz`;
	`gunzip -f gene2go.gz`;
	`gunzip -f uniprot_sprot.dat.gz`;
	if (-e "uniprot_trembl.dat") {
	} else {
		`gunzip -f uniprot_trembl.dat.gz`;
	}
	`gunzip -f interactions.gz`;
}


my $gofiles = "";
print STDERR "\tStep1: Pasing Uniprot...\n";
if ($preUniprot == 0) {
	`./accession/parseUniprot.pl uniprot_sprot.dat uniprot_trembl.dat > europe2ncbi.tsv`;
} else {
	print STDERR "\tSkipped uniprot parsing...\n";
}
$gofiles .= " gene3d.genes";
$gofiles .= " interpro.genes";
$gofiles .= " smart.genes";
$gofiles .= " pfam.genes";
$gofiles .= " prints.genes";
$gofiles .= " prosite.genes";

print STDERR "\tStep2: Creating conversion file for each organism...\n";
foreach (keys %orgs) {
	my $orgname = $_;
	my $taxid = $orgs{$_};
	print STDERR "Creating files for $orgname ($taxid)\n";
	`./accession/createIDConvFile.pl $taxid $orgname $addFiles europe2ncbi.tsv`;
}

print STDERR "\tStep3: Parsing Gene Ontology tree...\n";
`./GO/parseOntology_OBO.pl gene_ontology_edit.obo`;
`./GO/populateGOTreeWithGenes.pl biological_process.tree terms.tsv gene2go > biological_process.genes`;
`./GO/populateGOTreeWithGenes.pl molecular_function.tree terms.tsv gene2go > molecular_function.genes`;
`./GO/populateGOTreeWithGenes.pl cellular_component.tree terms.tsv gene2go > cellular_component.genes`;
$gofiles .= " biological_process.genes";
$gofiles .= " molecular_function.genes";
$gofiles .= " cellular_component.genes";

print STDERR "\tStep4: Parsing other ontologies...\n";
print STDERR "\t\tbiosystems (including KEGG)\n";
`./GO/createNCBIbiosystemOntology.pl`;
$gofiles .= " BIOCYC.biosystems.genes";
$gofiles .= " KEGG.biosystems.genes";
$gofiles .= " LIPID_MAPS.biosystems.genes";
$gofiles .= " Pathway_Interaction_Database.biosystems.genes";
$gofiles .= " REACTOME.biosystems.genes";
$gofiles .= " WikiPathways.biosystems.genes";

print STDERR "\t\tChromosome location\n";
`./GO/parseChrLocationOntology.pl`;
$gofiles .= " chromosome.genes";

print STDERR "\t\tprotein-protein interactions from ncbi gene(includes bind, etc.)\n";
`./GO/parseInteractions.pl interactions gene_info > interactions.genes`;
$gofiles .= " interactions.genes";

print STDERR "\t\tGWAS catalog\n";
`./GO/parseGWAScatalog.pl > gwas.genes`;
$gofiles .= " gwas.genes";

print STDERR "\t\tSMPDB pathways\n";
`./GO/parseSMPDB.pl human2gene.tsv > smpdb.genes`;
$gofiles .= " smpdb.genes";

print STDERR "\t\tCOSMIC cancer mutations\n";
`./GO/parseCOSMIC.pl human2gene.tsv > cosmic.genes`;
$gofiles .= " cosmic.genes";

print STDERR "\t\tMSigDB\n";
`./GO/addMSigDBtoHomer.pl msigdb.gmt human2gene.tsv homologene.data > msigdb.genes`;
$gofiles .= " msigdb.genes";
#`./addWikiPathways.pl wikipathways/ $destAcc/human2gene.tsv $destAcc/homologene.data > $destGO/wikipathways.genes`;
#`./addKeggPathways.pl kegg/ $destAcc/human2gene.tsv $destAcc/homologene.data > $destGO/kegg.genes`;

print STDERR "Moving output files to right directories...\n";
`cp $taxidFile $destAcc/`;
`cp GO.txt $destGO/`;
foreach (keys %orgs) {
	my $orgname = $_;
	my $id = $orgs{$orgname};
	my $convFile = $orgname . "2gene.tsv";
	my $descFile = $orgname . ".description";
	`./GO/filterGenesByOrganism.pl $orgname $descFile $gofiles`;

	#move files to output location
	`mv $convFile $destAcc/`;
	`mv $descFile $destAcc/`;
	`mv $orgname.* $destGO/`;

	#Update Config settings
	if (!exists($config->{'ORGANISMS'}->{$orgname})) {
		print STDERR "\tMaking new entry for $orgname in the config.txt file\n";
	}
	my @params = ($id,"NCBI Gene");
	my $g = {org=>$orgname,version=>$orgInfo{$orgname}->{'version'},location=>"data/accession/",
				url=>"LocalUpdate",desc=>"$orgInfo{$orgname}->{'fullName'} ($orgname) accession and ontology information",
				parameters=>\@params};
	$config->{'ORGANISMS'}->{$orgname} = $g;
    HomerConfig::printConfigFile($config);

}


print STDERR "Removing source files...\n";
if (1) {
	`rm gene2accession`;
	`rm gene2unigene`;
	`rm gene_info`;
	`rm gene2refseq`;
	`rm gene2ensembl`;
	`rm gene_history`;
	`rm gene2go`;
	`rm gene_ontology_edit.obo`;
	`rm uniprot_sprot.dat`;
	`rm interactions`;
	
	`rm europe2ncbi.tsv`;
	`rm biological_process.tree`;
	`rm molecular_function.tree`;
	`rm cellular_component.tree`;
	`rm terms.tsv`;
	`rm homologene.data`;
	`rm *.genes`;
}

print STDERR "\n\tFinished.\n";
print STDERR "\tuniprot_trembl.dat must be deleted manually (to save time if you need to rerun the command)\n\n";
