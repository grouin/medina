#!/usr/bin/perl

# Produit un tabulaire au format BIO à partir d'annotations
# embarquées. Ne gère pas les annotations imbriquées.

# Usage : perl zero_conversion.pl repertoire/ extension tabulaire

# Auteur : Cyril Grouin, octobre 2019.

use strict;
use utf8;

my @rep=<$ARGV[0]/*$ARGV[1]>;
my $sortie=$ARGV[2];

open(S,'>:utf8',"$sortie");
foreach my $fichier (@rep) {
  open(E,'<:utf8',$fichier);
  while (my $ligne=<E>) {
    # Ajout d'espaces autour des ponctuations, sauf celles utilisées dans les décimales ou dans les dates : - / .
    $ligne=~s/([\.\-,\(\)\|\'\’\@\#])/ $1 /g;
    $ligne=~s/(\d) \. (\d)/$1\.$2/g;
    $ligne=~s/(\d) \, (\d)/$1\,$2/g;
    $ligne=~s/aujourd \' hui/aujourd\'hui/g; $ligne=~s/aujourd \’ hui/aujourd\’hui/g;
    $ligne=~s/(.) ([\'\’]) (.)/$1$2 $3/g;
    $ligne=~s/http([^\s]+) \. ([^\s]+)/http$1\.$2/;
    # Réduction des espaces multiples
    $ligne=~s/\s+/ /g;
    $ligne=~s/^\s+//g;

    # Tokénisation
    my @tokens=split(/ /,$ligne);

    # Réinitialisations
    my $tag="O";
    my $prec="O";
    my $taille=0;
    my $interT=0;
    my $pos="nul";
    my $decl="nul";

    foreach my $token (@tokens) {
      my $fin="";

      # Balise ouvrante
      if ($token=~/<([^>\/]+)>/) {
	$tag=$1; $token=~s/<$tag>//;
      }
      # Le tag reste le même tant qu'on ne rencontre pas de balise fermante
      if ($token=~/<\/([^>]+)>/) {
	$fin=$1; $token=~s/<\/$fin>//;
      }

      # Taille absolue (nombre exact de caractères) et sur une échelle à trois valeurs
      $taille=length($token);
      if ($taille<4) { $interT="p"; } elsif ($taille<8) { $interT="m"; } else { $interT="g"; }

      # Mots outils
      if ($token=~/^(à|au|de|d\'|d\’|du|en|par|pour|sur|sous|avec|sans)$/i) { $pos="prep"; }
      elsif ($token=~/^(le|la|les|l\'|l\’|un|une|des)$/i) { $pos="det"; }
      elsif ($token=~/^(je|tu|il|elle|on|nous|vous|ils|elles)$/i) { $pos="proper"; }
      elsif ($token=~/^(ce|cet|cette|ces|celui|celle|ceux|celles)$/i) { $pos="dem"; }
      #elsif ($token=~/^(mais|ou|et|donc|or|ni|car)$/i) { $pos="conj"; }
      #elsif ($token=~/^(qui|que|quel|quelle|quels|quelles|quoi|où|quand|comment)$/i) { $pos="proint"; }
      else { $pos="nul"; }

      # Déclencheurs
      if ($token=~/^(Madame|madame|Monsieur|monsieur|Mme|M\.|Mr|Melle|Pr|PR|Professeur|professeur|Dr|DR|Docteur|docteur)$/) { $decl="pers"; }
      elsif ($token=~/^(janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre|lundi|mardi|mercredi|jeudi|vendredi|samedi|dimanche)$/i) { $decl="date"; }
      elsif ($token=~/^(CHU|clinique|hôpital|centre)$/i) { $decl="hosp"; }
      else { $decl="nul"; }

      # Affichage
      my $label="O";
      if ($tag eq "O") { $label="O"; }
      else { if ($tag eq $prec) { $label="I-$tag"; } else { $label="B-$tag"; } }
      print S "$token\t$taille\t$interT\t$pos\t$decl\t$label\n" if ($token ne "");

      # Réinitialisations
      if ($fin ne "") { $tag="O"; }
      $prec=$tag;
    }
    # Saut de ligne
    print S "\n";
  }
  close(E);
}
close(S);
