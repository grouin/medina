#!/usr/bin/perl

# Pour chaque fichier individuel de prédictions *sgml, crée un fichier
# d'annotation au format BRAT d'extension *.ann. S'il existe déjà des
# fichiers *.ann dans le répertoire (annotations de référence
# pré-existantes pour évaluer les performances), ils seront écrasés ;
# prévoir des sauvegardes.

# Usage : perl conversion-brat.pl répertoire/

# Auteur : Cyril Grouin, décembre 2019.


use strict;
use utf8;

my @rep=<$ARGV[0]/*sgml>;
my $id=$ARGV[1];

foreach my $fichier (@rep) {
  my $offset=0;
  my $i=$id."1";
  my $sortie=$fichier; $sortie=~s/sgml$/ann/;
  
  open(E,'<:utf8',$fichier);
  open(S,'>:utf8',$sortie);
  while (my $ligne=<E>) {
    # Tant qu'il y a des portions encadrées de balises ouvrantes et
    # fermantes, on supprime ces balises et on produit une ligne de
    # sortie dans le fichier d'annotation BRAT
    while ($ligne=~/<([A-Za-z]+)>([^<]+)<\/[A-Za-z]+>/) {
      my ($label,$portion)=($1,$2);
      $ligne=~s/<$label>\Q$portion\E<\/$label>/$portion/;
      # L'offset de début correspond au nombre de caractères depuis le
      # début du fichier ($offset) + le nombre de caractères depuis le
      # début de la ligne (fonction index). L'offset de fin ajoute à
      # l'offset de début la taille de la portion annotée.
      my $debut=$offset+index($ligne,$portion);
      my $fin=$debut+length($portion);
      # Affichage
      print S "T$i\t$label $debut $fin\t$portion\n";
      $i++;
    }
    
    if ($ligne eq "") { $offset++; } else { $offset+=length($ligne); }
  }
  close(E);
  close(S);
}


