#!/usr/bin/perl

# Conversion des formats BWEMO+ et BWEMO vers un format BIO2. Le
# fichier de prédictions pris en entrée est réécrit (même fichier
# d'entrée et de sortie). Permet de réaliser une évaluation correcte
# avec le script conlleval.pl
# Si des prédictions supplémentaires ont été faites, et qu'il ne faut
# pas les évaluer, lister ces catégories dans $suppressions ; ces
# prédictions en excès peuvent correspondre à des formes de surface
# ambigües pour un modèle délexicalisé (éponymes cliniques : mal. de
# Gougerot Sjögren ; synd. de Budd-Chiari ; thyroïdite de Hashimoto),
# mais dont les prédictions permettent néanmoins d'améliorer la
# reconnaissance d'autres catégories (en particulier Personne).

# Usage : perl post_conversion.pl sortie-zero

# Auteur : Cyril Grouin, janvier 2020.

use strict;
use utf8;

my $predictions=$ARGV[0];
my @contenu=();
my $suppressions="(Anatomie|Examen|Organisme|Pathologie|Substance|Traitement)";

open(E,'<:utf8',$predictions);
while (my $ligne=<E>) {
  # Modification des formats vers un format BIO2 classique
  $ligne=~s/W\-/B\-/g;
  $ligne=~s/[EMH]\-/I\-/g;
  $ligne=~s/O\-\S+/O/g;
  # Suppressions des prédictions à ne pas évaluer
  $ligne=~s/[BI]\-$suppressions/O/g;
  # Simplification des étiquettes Quaero
  #$ligne=~s/([BI]\-(loc|org|pers|prod|time))[\w\.\-]+/$1/g;
  # Stockage
  push(@contenu,$ligne);
}
close(E);

open(S,'>:utf8',$predictions);
foreach my $ligne (@contenu) {
  print S $ligne;
}
close(S);
