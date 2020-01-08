#!/usr/bin/perl

# Propage les prédictions du CRF sur les autres formes de surface
# identiques, pour les tokens composés d'au-moins 5 caractères, si les
# annotations existantes ont été réalisées sur au-moins 3 occurrences
# de cette forme.

# Usage : perl -CSDA post_propagation.pl sortie-zero >sortie-zero.prop

# Auteur : Cyril Grouin, janvier 2020.

use strict;
use utf8;

my $fichier=$ARGV[0];
my %memoire=();
my %frequences=();
my $colToken=1;


&memoriseAnnotations($fichier);
&appliqueAnnotations($fichier);


###
# Sous-programmes

sub memoriseAnnotations() {
  # Mémorise les annotations réalisées sur les tokens
  my $f=shift;
  open(E,'<:utf8',$f);
  while (my $ligne=<E>) {
    chomp $ligne;
    my @cols=split(/\t/,$ligne);
    if ($cols[$#cols] ne "O" && $cols[$#cols] ne "EOS") {
      $memoire{$cols[$colToken]}=$cols[$#cols];
        $frequences{"$cols[$colToken]$cols[$#cols]"}++;
       }
    }
  close(E);
}

sub appliqueAnnotations() {
  # Applique les annotations réalisées sur les tokens
  my $f=shift;
  open(E,'<:utf8',$f);
  while (my $ligne=<E>) {
    chomp $ligne;
    my @cols=split(/\t/,$ligne);
    my $fq=$frequences{"$cols[$colToken]$cols[$#cols]"};
    if (($cols[$#cols] eq "O" || $cols[$#cols]=~/EOS/) && exists $memoire{$cols[$colToken]} && $memoire{$cols[$colToken]} ne $cols[$#cols] && $fq>=5 && length($cols[$colToken]>=3)) {
      $ligne=~s/$cols[$#cols]$/$memoire{$cols[$colToken]}/g;
      print "$ligne\n";
    } else {
      print "$ligne\n";
    }
  }
  close(E);
}
