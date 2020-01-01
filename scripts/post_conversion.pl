#!/usr/bin/perl

# Conversion des formats BWEMO+ et BWEMO vers un format BIO2. Le
# fichier de prédictions pris en entrée est réécrit (même fichier
# d'entrée et de sortie). Permet de réaliser une évaluation correcte
# avec le script conlleval.pl

# Usage : perl post_conversion.pl sortie-zero

# Auteur : Cyril Grouin, janvier 2020.

use strict;
use utf8;

my $predictions=$ARGV[0];
my @contenu=();

open(E,'<:utf8',$predictions);
while (my $ligne=<E>) {
  # Modification des formats vers un format BIO2 classique
  $ligne=~s/W\-/B\-/g;
  $ligne=~s/[EMH]\-/I\-/g;
  $ligne=~s/O\-\S+/O/g;
  # Stockage
  push(@contenu,$ligne);
}
close(E);

open(S,'>:utf8',$predictions);
foreach my $ligne (@contenu) {
  print S $ligne;
}
close(S);
