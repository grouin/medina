#!/usr/bin/perl

# Produit un tabulaire au format BIO à partir d'annotations
# embarquées. Ne gère pas les annotations imbriquées.

# Usage : perl zero_tabulaire.pl repertoire/ extension nomFichierTabulaire format

# Formats d'annotation : IO BIO BWEMO

# Auteur : Cyril Grouin, octobre 2019.

use strict;
use utf8;
use Text::Soundex;

my @rep=<$ARGV[0]/*$ARGV[1]>;
my $sortie=$ARGV[2];
my $format=$ARGV[3];
my %frequence=();
my %frequenceC=();
my %frequenceV=();
my $total=0;
my $totalCar=0;
my $fichierPOS="data/forme-lemme-pos.tab";
my %tabPOS=();

warn "Applying $format annotation schema\n";

# Récupération des POS
open(E,$fichierPOS);
while (my $ligne=<E>) {
    chomp $ligne;
    my @cols=split(/\t/,$ligne);
    $tabPOS{$cols[0]}=$cols[2];
}
close(E);

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
my @tabulaire=();
my @labels=();
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

      # Etiquetage en parties du discours (d'après les listes du CNAM)
      if (exists $tabPOS{lc($token)}) { $pos=$tabPOS{lc($token)}; }
      else { $pos="nul"; }

      # Trigger words
      if ($token=~/^(Madame|madame|Monsieur|monsieur|Mme|M\.|Mr|Melle|Pr|PR|Professeur|professeur|Dr|DR|Docteur|docteur)$/) { $decl="pers"; }
      elsif ($token=~/^(janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre|lundi|mardi|mercredi|jeudi|vendredi|samedi|dimanche|monday|tuesday|wednesday|thursday|friday|saturday|sunday|january|february|march|april|may|june|july|august|september|october|november|december)$/i) { $decl="date"; }
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
      #else { if ($tag eq $prec) { $label="I-$tag"; } else { $label="B-$tag"; } }
      #print S "$token\t$taille\t$interT\t$pos\t$decl\t$freq\t$rareC\t$rareV\t$soundex\t$label\n" if ($token ne "");
      if ($token ne "") {
	  push(@tabulaire,"$token\t$taille\t$interT\t$pos\t$decl\t$freq\t$rareC\t$rareV\t$soundex\t");
	  push(@labels,$tag);
      }

      # Reinitializations
      if ($fin ne "") { $tag="O"; }
      $prec=$tag;
    }
    # New line
    #print S "\n";
    push(@tabulaire,"");
    push(@labels,"");
  }
  close(E);
}

open(S,'>:utf8',"$sortie");
my $i=0;
foreach my $ligne (@tabulaire) {
    my $tag="";
    # Format BWEMO
    if ($format eq "BWEMO") {
	# - W-annotation isolée
	if (($labels[$i-1] eq "O" || $labels[$i-1] eq "") && $labels[$i] ne "O" && $labels[$i] ne "" && ($labels[$i+1] eq "O" || $labels[$i+1] eq "")) { $tag="W-$labels[$i]"; }
	# - B-début d'annotation
	elsif (($labels[$i-1] eq "O" || $labels[$i-1] eq "") && $labels[$i] ne "O" && $labels[$i+1] ne "O" && $labels[$i] ne "" && $labels[$i+1] ne "") { $tag="B-$labels[$i]"; }
	# - M-milieu d'annotation
	elsif ($labels[$i-1] eq $labels[$i] && $labels[$i] ne "O" && $labels[$i] ne "" && $labels[$i+1] ne "O" && $labels[$i+1] ne "") { $tag="M-$labels[$i]"; }
	# - E-fin d'annotation
	elsif ($labels[$i-1] eq $labels[$i] && $labels[$i] ne "O" && $labels[$i] ne "" && ($labels[$i+1] eq "O" || $labels[$i+1] eq "") && $labels[$i+1] ne $labels[$i]) { $tag="E-$labels[$i]"; }
	# - O le cas échéant
	else { $tag="O"; }
    }
    # Format IO
    elsif ($format eq "IO") {
	# - I-début/milieu/fin d'annotation
	if (($labels[$i-1] eq "O" || $labels[$i-1] eq "") && $labels[$i] ne "O" && $labels[$i+1] ne "O" && $labels[$i] ne "" && $labels[$i+1] ne "") { $tag="I-$labels[$i]"; }
	elsif ($labels[$i-1] eq $labels[$i] && $labels[$i] ne "O" && $labels[$i] ne "" && $labels[$i+1] ne "O" && $labels[$i+1] ne "") { $tag="I-$labels[$i]"; }
	elsif ($labels[$i-1] eq $labels[$i] && $labels[$i] ne "O" && $labels[$i] ne "" && ($labels[$i+1] eq "O" || $labels[$i+1] eq "")) { $tag="I-$labels[$i]"; }
	# - O le cas échéant
	else { $tag="O"; }
    }
    # Format BIO (par défaut)
    else {
	# - B-début d'annotation ou annotation isolée
	if (($labels[$i-1] eq "O" || $labels[$i-1] eq "") && $labels[$i] ne "O" && $labels[$i] ne "" && ($labels[$i+1] eq "O" || $labels[$i+1] eq "")) { $tag="B-$labels[$i]"; }
	elsif (($labels[$i-1] eq "O" || $labels[$i-1] eq "") && $labels[$i] ne "O" && $labels[$i+1] ne "O" && $labels[$i] ne "" && $labels[$i+1] ne "") { $tag="B-$labels[$i]"; }
	# - I-milieu/fin d'annotation
	elsif ($labels[$i-1] eq $labels[$i] && $labels[$i] ne "O" && $labels[$i] ne "" && $labels[$i+1] ne "O" && $labels[$i+1] ne "") { $tag="I-$labels[$i]"; }
	elsif ($labels[$i-1] eq $labels[$i] && $labels[$i] ne "O" && $labels[$i] ne "" && ($labels[$i+1] eq "O" || $labels[$i+1] eq "")) { $tag="I-$labels[$i]"; }
	# - O le cas échéant
	else { $tag="O"; }
    }
    if ($labels[$i] eq "") { $tag=""; }

    print S "$ligne$tag\n";
    $i++;
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
