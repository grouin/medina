#!/usr/bin/perl

# Auteur : Cyril Grouin, décembre 2019.


use strict;
use utf8;
use vars qw($opt_r $opt_e);
use Getopt::Std;

&getopts("r:e:");
if (!$opt_r) { die "Usage :\tperl post_pseudonymization.pl -r <directory> -e <extension sgml/dat>\n"; }

my $ext;
(!$opt_e) ? ($ext="sgml") : ($ext=$opt_e);
my @rep=<$opt_r/*.$ext>;

my ($entree,$sortie,$ligne);
my (%index,%corrN,%corrP,%corr);

# Table de correspondance : les 20 noms de famille les plus portés en
# France. S'il y a plus de 20 noms dans le compte-rendu, le script
# remplacera les noms par du vide, à compléter en conséquence.
# http://www.journaldesfemmes.com/nom-de-famille/
%corrN=(
  "1"=>"Martin",
  "2"=>"Bernard",
  "3"=>"Dubois",
  "4"=>"Thomas",
  "5"=>"Robert",
  "6"=>"Richard",
  "7"=>"Petit",
  "8"=>"Durand",
  "9"=>"Leroy",
  "10"=>"Moreau",
  "11"=>"Simon",
  "12"=>"Laurent",
  "13"=>"Lefebvre",
  "14"=>"Michel",
  "15"=>"Garcia",
  "16"=>"David",
  "17"=>"Bertrand",
  "18"=>"Roux",
  "19"=>"Vincent",
  "20"=>"Fournier",
);

# 20 prénoms mixtes
%corrP=(
  "1"=>"Alex",
  "2"=>"Camille",
  "3"=>"Charlie",
  "4"=>"Claude",
  "5"=>"Dominique",
  "6"=>"Maxime",
  "7"=>"Morgan",
  "8"=>"Stéphane",
  "9"=>"Louison",
  "10"=>"Maé",
  "11"=>"Noa",
  "12"=>"Sacha",
  "13"=>"Lou",
  "14"=>"Andréa",
  "15"=>"Alix",
  "16"=>"Eden",
  "17"=>"Loan",
  "18"=>"Ambre",
  "19"=>"Amael",
  "20"=>"Ariel"
);





# Extraction des prédictions réalisées
foreach $entree (@rep) {
  open(E,'<:utf8',$entree);
  while ($ligne=<E>) {
    while ($ligne=~/<Personne>([^<]+)<\/Personne>/i) {
      my $personne=$1;
      $index{$personne}++;
      $ligne=~s/<Personne>$personne<\/Personne>/$personne/gi;
    }
  }
  close(E);
}

# Attribution de correspondances valables sur l'ensemble du corpus
foreach my $personne (sort keys %index) {
  my ($prenom,$nom)=&recuperePrenomNom($personne);

  # Tirage aléatoire de prénom et nom dans les listes existantes
  my ($p,$n)=($corrP{int(rand(19)+1)},$corrN{int(rand(19)+1)});

  # Génération des variantes (prénom et nom en majuscules, prénom en
  # minuscules et nom en majuscules, prénom et nom en minuscules avec
  # initiale en majuscule, versions avec initiale du prénom)
  &prenomMajNomMaj($prenom,$nom,$p,$n);
  &prenomMinNomMaj($prenom,$nom,$p,$n);
  &iniPrenomNomMaj($prenom,$nom,$p,$n);
  &prenomMinNomMin($prenom,$nom,$p,$n);
  &iniPrenomNomMin($prenom,$nom,$p,$n);
}


foreach $entree (@rep) {
  # Output file extension
  $sortie=substr($entree,0,length($entree)-3)."pse";
  warn "Produit $sortie\n";

  open(E,'<:utf8',$entree);
  open(S,'>:utf8',$sortie);
  while ($ligne=<E>) {
    while ($ligne=~/<Personne>([^<]+)<\/Personne>/i) {
      my $personne=$1;
      if (exists $corr{$personne}) {
	#warn "identifie $personne\n";
	$ligne=~s/<Personne>$personne<\/Personne>/$corr{$personne}/gi;
      } else {
	warn "manque : $personne\n";
	$ligne=~s/<Personne>$personne<\/Personne>/$personne/gi;
      }
    }
    print S $ligne;
  }
  close(E);
  close(S);
}


###
# Routines

sub recuperePrenomNom() {
  # Identifie les prénom et nom dans un segment annoté Personne, en
  # segmentant autour de l'espace : l'élément avant la première espace
  # est le prénom, tous les autres éléments font partie du nom

  my $segment=shift;
  
  my ($e1,$e2,$e3,$e4)=split(/ /,$segment);
  if ($e4 ne "") { $e3.=" $e4"; $e4=""; }
  if ($e3 ne "") { $e2.=" $e3"; $e3=""; }
  if ($e2 eq "" && $e1=~/^\p{Lu}+$/) { $e2=$e1; $e1=""; }

  return ($e1,$e2);
}


sub prenomMajNomMaj() {
  my ($prenomReel,$nomReel,$substitutPrenom,$substitutNom)=@_;
  
  $substitutNom=uc($substitutNom); $substitutPrenom=uc($substitutPrenom);
  my $cle=uc("$prenomReel $nomReel");
  if ($prenomReel ne "") { $corr{$cle}="$substitutPrenom $substitutNom"; } else { $corr{$cle}="$substitutNom"; }
  $corr{$prenomReel}=$substitutPrenom;
  #print "-(1) $cle/$substitutPrenom $substitutNom\n";
}

sub prenomMinNomMaj() {
  my ($prenomReel,$nomReel,$substitutPrenom,$substitutNom)=@_;
  my $prenomReelNormalise=&minusculesMajusculeInitiale($prenomReel);
  my $substitutPrenomNorm=&minusculesMajusculeInitiale($substitutPrenom);

  my $cle; if ($prenomReel ne "") { $cle=$prenomReelNormalise." ".uc($nomReel); } else { $cle=uc($nomReel); }
  
  $corr{$cle}="$substitutPrenomNorm $substitutNom";
  #print "-(2) $cle/$substitutPrenomNorm $substitutNom\n";
  my $cle2=substr($prenomReel,0,1).lc(substr($prenomReel,1));
  $corr{$cle2}="$substitutPrenomNorm";
}

sub iniPrenomNomMaj() {
  my ($prenomReel,$nomReel,$substitutPrenom,$substitutNom)=@_;

  my $ip=substr($substitutPrenom,0,1)."\.";
  my $cle; if ($prenomReel ne "") { $cle=substr($prenomReel,0,1)." ".uc($nomReel); } else { $cle=uc($nomReel); }
  
  $corr{$cle}="$ip $substitutNom";
  #print "-(3) $cle/$ip $substitutNom\n";

  $cle=uc($nomReel);
  $corr{$cle}="$substitutNom";
  #print "-(4) $cle/$substitutNom\n";
}

sub prenomMinNomMin() {
  my ($prenomReel,$nomReel,$substitutPrenom,$substitutNom)=@_;
  my $prenomReelNormalise=&minusculesMajusculeInitiale($prenomReel);
  my $nomReelNormalise=&minusculesMajusculeInitiale($nomReel);

  my $cle; if ($prenomReel ne "") { $cle=$prenomReelNormalise." ".$nomReelNormalise; } else { $cle=$nomReelNormalise; }
  $corr{$cle}="$substitutPrenom $substitutNom";
  #print "-(5) $cle/$substitutPrenom $substitutNom\n";
}

sub iniPrenomNomMin() {
  my ($prenomReel,$nomReel,$substitutPrenom,$substitutNom)=@_;
  my $nomReelNormalise=&minusculesMajusculeInitiale($nomReel);

  my $ip=substr($substitutPrenom,0,1)."\.";
  my $cle; if ($prenomReel ne "") { $cle=substr($prenomReel,0,1)." ".$nomReelNormalise; } else { $cle=$nomReelNormalise; }
  $corr{$cle}="$ip $substitutNom";
  #print "-(6) $cle/$ip $substitutNom\n";
}


sub minusculesMajusculeInitiale() {
  # Pour un nom ou prénom simple ou composé, renvoie ledit nom ou
  # prénom avec une majuscule initiale et le reste en minuscules
  # (Jean, Jean Luc, Jean-Luc)
  my $element=shift;

  my $normalisation;
  if ($element=~/ /) { my @c=split(/ /,$element); foreach my $t (@c) { $normalisation.=" ".substr($t,0,1).lc(substr($t,1)); } $normalisation=~s/^ //; }
  elsif ($element=~/\-/) { my @c=split(/\-/,$element); foreach my $t (@c) { $normalisation.="\-".substr($t,0,1).lc(substr($t,1)); } $normalisation=~s/^\-//; }
  else { $normalisation=substr($element,0,1).lc(substr($element,1)); }

  return $normalisation;
}
