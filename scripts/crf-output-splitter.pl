#!/usr/bin/perl

# Segmente le fichier de prédictions CRF en autant de fichiers
# individuels qu'à l'origine (extension *sgml) dans le répertoire des
# fichiers traités, convertit les noms de fichier en ASCII (seul
# encodage possible pour BRAT qui repose sur Python 2.7)

# Usage : perl crf-output-splitter.pl tabulairePrédictions repertoireSortie

# Auteur : Cyril Grouin, décembre 2019.


use strict;
use utf8;
use Encode;

my $tabulaire=$ARGV[0];
my $repSortie=$ARGV[1];
my $fichier="";
my %fichiers=();
my %labels=();
my $numLigneFichier;
my $numTokenLigne;

open(E,'<:utf8',$tabulaire);
while (my $ligne=<E>) {
  chomp $ligne;
  my @cols=split(/\t/,$ligne);
  my ($numeroLigne,$offset)=split(/\-/,$cols[0]);

  # Nom du fichier et réinitialisations
  if ($ligne=~/^([^\s]+\.(tag|txt))\t/) {
    $fichier=$1;
    $fichier=~s/(tag|txt)$/sgml/;
    if ($repSortie ne "") { $fichier=~s/^.*\///; $fichier="$repSortie\/".$fichier; }
    $numLigneFichier=0;
    $numTokenLigne=0;
    Encode::from_to($fichier, 'utf8', 'ascii'); $fichier=~s/\?/\-/g;
  }
  else {
    # Ligne non vide, on récupère le token et l'annotation
    if ($ligne ne "") {
      # Gestion des sauts de ligne par ajout d'autant de lignes vides
      # que nécessaire
      while ($numLigneFichier<$numeroLigne) { $fichiers{$fichier}.="\n"; $numLigneFichier++; }
      # Gestion des offsets de caractères par ajout d'espaces en
      # fonction des écarts constatés entre offset du fichier
      # d'origine et offset calculé
      if ($numTokenLigne<$offset) { while ($numTokenLigne<$offset) { $numTokenLigne++; $fichiers{$fichier}.=" "; } }

      my $tag=$cols[$#cols]; $tag=~s/^[BIWEM]\-//; $tag=~s/^O\-.+$/O/;
      # Stockage des labels possibles
      $labels{$tag}++;
      # Récupération des informations utiles
      my $token=$cols[1];
      if ($tag ne "O") { $fichiers{$fichier}.="<$tag>$token<\/$tag>"; }
      else { $fichiers{$fichier}.="$token"; }
      $numTokenLigne+=length($token);
    }
    # Une ligne vide correspond à un saut de ligne : incrémentation du
    # compteur du numéro de ligne en cours de traitement et remise à
    # zéro du numéro de token sur la ligne
    else { $fichiers{$fichier}.="\n"; $numLigneFichier++; $numTokenLigne=0; }
  }
}
close(E);

# Production du fichier de sortie
foreach my $fichier (sort keys %fichiers) {
  open(S,'>:utf8',"$fichier") or die "Impossible d'écrire dans $fichier\n";
  my $contenu=$fichiers{$fichier};
  foreach my $tag (sort keys %labels) { $contenu=~s/<\/$tag>(\s*)<$tag>/$1/g; }
  # 28-03-2022 sortie avec attributs (en fonction de la classe d'entité)
  $contenu=~s/<Personne\_(\w+)>/<Personne role=\"$1\">/g;
  $contenu=~s/<Lieu\_(\w+)>/<Lieu type=\"$1\">/g;
  $contenu=~s/<Id\_(\w+)>/<Id categorie=\"$1\">/g;
  $contenu=~s/<Autre\_(\w+)>/<Autre classe=\"$1\">/g;
  $contenu=~s/<emotion\_(\w+)>/<emotion valence=\"$1\">/g;
  $contenu=~s/<\/(\w+)\_(\w+)>/<\/$1>/g;
  print S "$contenu\n";
  close(S);
}
