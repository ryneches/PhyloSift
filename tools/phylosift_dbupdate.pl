#!/usr/bin/env perl
use warnings;
use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Getopt::Long;
use Phylosift::Phylosift;
use Carp;
use Phylosift::Utilities qw(debug);
use Phylosift::UpdateDB;
die "Usage: phylosift_dbupdate.pl <data repository path> <destination marker path> [knockout list]" if @ARGV < 2;
my $repository               = $ARGV[0];
my $destination              = $ARGV[1];
my $taxon_knockouts          = $ARGV[2];
#my $local = "/state/partition1/koadman/phylosift_extended_dbupdate/";
my $local = "/state/partition1/koadman/phylosift_dbupdate/";
my $ebi_repository           = $repository . "/ebi";
my $ncbi_draft_repository    = $repository . "/ncbi_draft";
my $ncbi_finished_repository = $repository . "/ncbi_finished";
my $local_repository         = $repository . "/local";
my $result_repository        = $destination . "/processed";
my $marker_dir               = $destination . "/markers";
my $newObject                = new Phylosift::Phylosift();
my @new_genomes              = ();

$newObject->{"updated"}=0;	# don't default to updated markers
Phylosift::Phylosift::read_phylosift_config(self=>$newObject);
Phylosift::Utilities::data_checks( self => $newObject );

# force use of the new NCBI data
$Phylosift::Utilities::ncbi_dir = "$repository/ncbi/";

#Phylosift::UpdateDB::get_ebi_genomes( directory => $ebi_repository );
#Phylosift::UpdateDB::get_ncbi_draft_genomes( directory => $ncbi_draft_repository );
#Phylosift::UpdateDB::get_ncbi_finished_genomes( directory => $ncbi_finished_repository );
#Phylosift::UpdateDB::find_new_genomes( genome_directory => $ncbi_finished_repository, results_directory => $local, files => \@new_genomes );
#Phylosift::UpdateDB::find_new_genomes( genome_directory => $ncbi_draft_repository,    results_directory => $local, files => \@new_genomes );
#Phylosift::UpdateDB::find_new_genomes( genome_directory => $ebi_repository,           results_directory => $local, files => \@new_genomes );
#Phylosift::UpdateDB::find_new_genomes( genome_directory => $local_repository,         results_directory => $local, files => \@new_genomes );
#Phylosift::UpdateDB::qsub_updates( local_directory => $local, files => \@new_genomes );
Phylosift::UpdateDB::collate_markers( local_directory => $local, marker_dir => $marker_dir, taxon_knockouts => $taxon_knockouts );
Phylosift::UpdateDB::assign_seqids( marker_directory => $marker_dir );
Phylosift::UpdateDB::update_rna( self => $newObject, marker_dir => $marker_dir );
Phylosift::UpdateDB::update_ncbi_taxonomy( repository => $repository );
debug "Updating NCBI tree and taxon map...";
Phylosift::UpdateDB::make_ncbi_tree_from_update( self => $newObject, marker_dir => $marker_dir, repository => $repository );
debug "done\n";
Phylosift::UpdateDB::build_marker_trees_fasttree( marker_directory => $marker_dir, pruned => 0 );
Phylosift::UpdateDB::make_codon_submarkers( marker_dir => $marker_dir );
Phylosift::UpdateDB::pd_prune_markers( marker_directory => $marker_dir );
Phylosift::UpdateDB::build_marker_trees_fasttree( marker_directory => $marker_dir, pruned => 1 );
#Phylosift::UpdateDB::make_pplacer_packages_with_taxonomy(marker_dir => $marker_dir);
Phylosift::UpdateDB::reconcile_with_ncbi( self => $newObject, marker_directory => $marker_dir, pruned => 1 );
#Phylosift::UpdateDB::join_trees( marker_dir => $marker_dir );
Phylosift::UpdateDB::package_markers( marker_directory => $marker_dir );
