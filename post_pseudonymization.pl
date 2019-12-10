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
    my ($prenom,$nom,$nom2,$nom3)=split(/ /,$personne);
    if ($nom3 ne "") { $nom2.=" $nom3"; $nom3=""; }
    if ($nom2 ne "") { $nom.=" $nom2"; $nom2=""; }
    if ($nom eq "" && $prenom=~/^\p{Lu}+$/) { $nom=$prenom; $prenom=""; }
    #print "prenom=$prenom nom=$nom\n";
    # Tirage aléatoire de prénom et nom dans les listes existantes
    my ($p,$n)=($corrP{int(rand(19)+1)},$corrN{int(rand(19)+1)});
    
    # - PRENOM NOM
    $n=uc($n); $p=uc($p);
    my $cle=uc($personne);
    if ($prenom ne "") { $corr{$cle}="$p $n"; } else { $corr{$cle}="$n"; }
    $corr{$prenom}=$p;
    #print "-(1) $cle/$p $n\n";
    
    # - Prénom NOM
    my $prenom2=""; my $p2="";
    if ($prenom=~/ /) { my @c=split(/ /,$prenom); foreach my $t (@c) { $prenom2.=" ".substr($t,0,1).lc(substr($t,1)); } $prenom2=~s/^ //; }
    elsif ($prenom=~/\-/) { my @c=split(/\-/,$prenom); foreach my $t (@c) { $prenom2.="\-".substr($t,0,1).lc(substr($t,1)); } $prenom2=~s/^\-//; }
    else { $prenom2=substr($prenom,0,1).lc(substr($prenom,1)); }
    if ($p=~/ /) { my @c=split(/ /,$p); foreach my $t (@c) { $p2.=" ".substr($t,0,1).lc(substr($t,1)); } $p2=~s/^ //; }
    elsif ($p=~/\-/) { my @c=split(/\-/,$p); foreach my $t (@c) { $p2.="\-".substr($t,0,1).lc(substr($t,1)); } $p2=~s/^\-//; }
    else { $p2=substr($p,0,1).lc(substr($p,1)); }
    if ($prenom ne "") { $cle=$prenom2." ".uc($nom); } else { $cle=uc($nom); }
    $corr{$cle}="$p2 $n";
    #print "-(2) $cle/$p2 $n\n";
    my $cle2=substr($prenom,0,1).lc(substr($prenom,1));
    $corr{$cle2}="$p2";

    # - P. NOM
    my $ip=substr($p,0,1)."\.";
    if ($prenom ne "") { $cle=substr($prenom,0,1)." ".uc($nom); } else { $cle=uc($nom); }
    $corr{$cle}="$ip $n";
    $cle2=uc($nom); $corr{$cle2}="$n";
    #print "-(3) $cle/$ip $n\n";
    #print "-(4) $cle2/$n\n";

    # - Prénom Nom
    my $nom2="";
    if ($nom=~/ /) { my @c=split(/ /,$nom); foreach my $t (@c) { $nom2.=" ".substr($t,0,1).lc(substr($t,1)); } $nom2=~s/^ //; }
    elsif ($nom=~/\-/) { my @c=split(/\-/,$nom); foreach my $t (@c) { $nom2.="\-".substr($t,0,1).lc(substr($t,1)); } $nom2=~s/^\-//; }
    else { $nom2=$nom; }
    if ($prenom ne "") { $cle=$prenom2." ".$nom2; } else { $cle=$nom2; }
    $corr{$cle}="$p $n";
    #print "-(5) $cle/$p $n\n";

    # - P. Nom
    my $ip=substr($p,0,1)."\.";
    if ($prenom ne "") { $cle=substr($prenom,0,1)." ".$nom2; } else { $cle=$nom2; }
    $corr{$cle}="$ip $n";
    #print "-(6) $cle/$ip $n\n";
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
