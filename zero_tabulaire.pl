#!/usr/bin/perl

# Produit un tabulaire au format BIO à partir d'annotations
# embarquées. Ne gère pas les annotations imbriquées.

# Usage : perl zero_conversion.pl repertoire/ extension tabulaire

# Auteur : Cyril Grouin, octobre 2019.

use strict;
use utf8;
use Text::Soundex;

my @rep=<$ARGV[0]/*$ARGV[1]>;
my $sortie=$ARGV[2];
my %frequence=();
my %frequenceC=();
my %frequenceV=();
my $total=0;
my $totalCar=0;

# Premier parcours du corpus : calcul de la fréquence d'utilisation de
# chaque token du corpus traité
foreach my $fichier (@rep) {
  open(E,'<:utf8',$fichier);
  while (my $ligne=<E>) {
    my $norm=&normalisation($ligne);

    # Tokénisation
    my @tokens=split(/ /,$norm);
    foreach my $token (@tokens) { $frequence{$token}++; $total++; }
    # Tokénisation caractères
    my @cars=split(//,$norm);
    foreach my $car (@cars) {
	$car=lc($car);
	$frequenceC{$car}++ if ($car=~/[bcdfghjklmnpqrstvwxzç]/i);
	$frequenceV{$car}++ if ($car=~/[aeiouyàâéèêëîïôöûùü]/i);
	$totalCar++;
    }
  }
}



# Deuxième parcours du corpus : traitement du corpus et production du
# tabulaire
open(S,'>:utf8',"$sortie");
foreach my $fichier (@rep) {
  open(E,'<:utf8',$fichier);
  while (my $ligne=<E>) {
    my $norm=&normalisation($ligne);

    # Tokenization
    my @tokens=split(/ /,$norm);

    # Rzinitializations
    my $tag="O";
    my $prec="O";
    my $taille=0;
    my $interT=0;
    my $pos="nul";
    my $decl="nul";

    foreach my $token (@tokens) {
      my $fin="";
      my $freq="rare";
      my $rareC="nul";
      my $rareV="nul";

      # Opening tag
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

      # Trigger words
      if ($token=~/^(Madame|madame|Monsieur|monsieur|Mme|M\.|Mr|Melle|Pr|PR|Professeur|professeur|Dr|DR|Docteur|docteur)$/) { $decl="pers"; }
      elsif ($token=~/^(janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre|lundi|mardi|mercredi|jeudi|vendredi|samedi|dimanche)$/i) { $decl="date"; }
      elsif ($token=~/^(CHU|clinique|hôpital|centre)$/i) { $decl="hosp"; }
      else { $decl="nul"; }

      # Fréquence d'utilisation du token dans le corpus (binaire)
      if ($frequence{$token}<=($total/2000) && $token=~/^\p{L}+$/i) { $freq="rare"; } else { $freq="commun"; }
      # Fréquence d'utilisation des caractères du token dans le corpus (soit il y a des consonnes ou des voyelles rares dans le token, soit il n'y en a pas)
      my @cars=split(//,$token);
      foreach my $car (@cars) {
	  $car=lc($car);
	  if ($car=~/[bcdfghjklmnpqrstvwxzç]/) { if ($frequenceC{$car}<=($totalCar/250)) { $rareC="cons"; } }
	  if ($car=~/[aeiouyàâéèêëîïôöûùü]/) { if ($frequenceV{$car}<=($totalCar/250)) { $rareV="voy"; } }
      }

      # Code Soundex
      my $soundex="NUL";
      $soundex=soundex($token) if ($token=~/^\p{L}+$/);
      if ($soundex eq "") { $soundex="NUL"; }

      # Printing
      my $label="O";
      if ($tag eq "O") { $label="O"; }
      else { if ($tag eq $prec) { $label="I-$tag"; } else { $label="B-$tag"; } }
      print S "$token\t$taille\t$interT\t$pos\t$decl\t$freq\t$rareC\t$rareV\t$soundex\t$label\n" if ($token ne "");

      # Reinitializations
      if ($fin ne "") { $tag="O"; }
      $prec=$tag;
    }
    # New line
    print S "\n";
  }
  close(E);
}
close(S);


###
# Routines

sub normalisation() {
  my $contenu=shift;
  # Ajout d'espaces autour des ponctuations, sauf celles utilisées
  # dans les décimales ou dans les dates : - / .
  $contenu=~s/([\.\-,\(\)\|\'\’\@\#])/ $1 /g;
  $contenu=~s/(\d) \. (\d)/$1\.$2/g;
  $contenu=~s/(\d) \, (\d)/$1\,$2/g;
  $contenu=~s/aujourd \' hui/aujourd\'hui/g; $contenu=~s/aujourd \’ hui/aujourd\’hui/g;
  $contenu=~s/(.) ([\'\’]) (.)/$1$2 $3/g;
  $contenu=~s/http([^\s]+) \. ([^\s]+)/http$1\.$2/;
  # Réduction des espaces multiples
  $contenu=~s/\s+/ /g;
  $contenu=~s/^\s+//g;

  return $contenu;
}
