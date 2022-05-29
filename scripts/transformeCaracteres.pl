#!/usr/bin/perl

# Transforme chaque caractère d'un texte par un caractère de la même
# classe (chiffres, consonnes, voyelles sans diacritique, voyelles
# avec diacritique).
#
# - le même caractère n'est pas systématiquement remplacé de la même
# manière et réciproquement : scanner abdominal => rruwmob escumekaf
# (les deux 'n' de 'scanner' deviennent un 'w' et un 'm' ; les deux
# 'r' de 'rruwmob' correspondent aux 's' et 'c' de 'scanner')
# - en revanche, la même forme de surface d'un corpus sera toujours
# transformée de la même manière dans le corpus : une dilation
# kystique ... avec une dilatation modérée => efo ducagateib gocsarua
# ... oquf efo ducagateib vepûnèi ('une' devient 'efo', 'dilatation'
# devient 'ducagateib')
# - l'information de casse typographique est conservée, de ce fait,
# comme la forme de surface tout en majuscules diffère de la forme
# majuscule à l'initiale avec le reste en minuscules, deux mots dans
# des casses différentes seront générés de deux manières différentes :
# SERVICE => NAKWUBO ; Chef de service => Mvuk he danxupi
# - les ponctuations sont conservées à l'identique (utile pour repérer
# les adresses mails et les dates)
# - enfin, les chiffres sont remplacés par des chiffres (dates,
# téléphones, valeurs de laboratoire, etc.), les consonnes sont
# remplacées par des consonnes, les voyelles par des voyelles, les
# diacritiques sont remis aux mêmes endroits, de manière à générer un
# texte "prononçable". Les diacritiques sont ceux du français :
# Confrère => Puwwbêse ; a été hospitalisée => o ébï fefgepekadîe
#
# Chaque lancement du script produit de nouvelles substitutions. Les
# exemples donnés ici correspondent à un lancement et sont donc
# uniques. Produit des fichiers d'extension *.alea

# Usage : perl transformeCaracteres.pl repertoire/ txt

# Auteur : Cyril Grouin, juillet 2021.


use strict;
use utf8;

die "perl transformeCaracteres.pl repertoire/ txt\n" if ($#ARGV!=1);
my @rep=<$ARGV[0]/*$ARGV[1]>;
my @vocD=("0".."9");
my @vocC=("b","c","d","f","g","h","j","k","l","m","n","p","q","r","s","t","v","w","x","z");
my @vocV=("a","e","i","o","u","y");
my @vocA=("à","â","é","è","ê","ë","î","ï","ô","û","ù");
my @vocP=(".","\,","\;",":","?","!","-","#","\@","\"","\$","_","\(","\)","\[","\]","\&","\/","*","+","=","§");
my %deja=();

foreach my $fichier (@rep) {
  my $sortie="$fichier\.alea";
  warn "Produit $sortie\n";
  open(E,'<:utf8',$fichier);
  open(S,'>:utf8',$sortie);
  while (my $ligne=<E>) {
    chomp $ligne;
    my @cars=split(//,$ligne);
    my ($avant,$apres)=("","");
    foreach my $car (@cars) {
      # Chiffre
      if ($car=~/\d/) {
	my $n=$vocD[int(rand($#vocD))];
	$avant.="$car"; $apres.="$n";
      }
      # # Ponctuation
      # elsif ($car=~/\'/) { print S "\'"; }
      # elsif ($car=~/[[:punct:]]/) { print S $vocP[int(rand($#vocP))+1]; }
      # Ponctuation : reprise à l'identique
      elsif ($car=~/[[:punct:]]/) {
	$avant.="$car"; $apres.="$car";
      }
      # Alphabet
      elsif ($car=~/\p{L}/) {
	# Consonnes
	if ($car=~/[bcdfghjklmnpqrstvwxzç]/i) {
	  my $n=$vocC[int(rand($#vocC))];
	  if ($car=~/[[:upper:]]/) { $n=uc($n); }
	  $avant.="$car"; $apres.="$n";
	}
	# Voyelles sans diacritique
	elsif ($car=~/[aeiouy]/i) {
	  my $n=$vocV[int(rand($#vocV))];
	  if ($car=~/[[:upper:]]/) { $n=uc($n); }
	  $avant.="$car"; $apres.="$n";
	}
	# Voyelles avec diacritiques
	else {
	  my $n=$vocA[int(rand($#vocA))];
	  if ($car=~/[[:upper:]]/) { $n=uc($n); }
	  $avant.="$car"; $apres.="$n";
	}
      }
	
      # Espace : impression, stockage et réinitialisations
      elsif ($car eq " ") {
	# Si la modification a déjà été effectuée (sur une autre
	# ligne), on conserve la modification précédente (le même mot
	# est toujours transformé de la même manière)
	if (exists $deja{$avant}) { $apres=$deja{$avant}; }
	else { $deja{$avant}=$apres; }
	print S "$apres ";
	$avant=""; $apres="";
      }
      
    }
    # Fin de ligne (dernier caractère) : impression, stockage et
    # réinitialisations
    if (exists $deja{$avant}) { $apres=$deja{$avant}; }
    else { $deja{$avant}=$apres; }
    print S "$apres";
    $avant=""; $apres="";

    print S "\n";
  }
  close(E);
  close(S);
}

# Impression de la correspondance du lexique avant/après
open(S,'>:utf8',"lexique-corresp.txt");
foreach my $token (sort keys %deja) { print S "$token\t$deja{$token}\n"; }
close(S);
