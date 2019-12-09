#!/usr/bin/perl

# Produit un tabulaire au format voulu à partir d'annotations
# embarquées. Ne gère pas les annotations imbriquées.

# Usage : perl zero_tabulaire.pl repertoire/ extension nomFichierTabulaire format

# Formats : IO BIO BIO2 (le plus courant) BIO2H BWEMO BWEMO+
# - IO : in/out
# - BIO : begin/in/out, un élément isolé reçoit le préfixe I
# - BIO2 : begin/in/out, un élément isolé reçoit le préfixe B
# - BIO2H : begin/in/out, la tête de syntagme reçoit le préfixe H
# - BWEMO : begin/word/end/middle/out, un élément isolé reçoit le
#   préfixe W, le dernier élément annoté reçoit le préfixe E
# - BWEMO+ : idem, les fins de ligne reçoivent l'étiquette O-EOS, et
#   les O qui précèdent une portion annotée reçoivent l'étiquette de
#   la portion qui suit avec le préfixe O

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
    # Ajout d'une version désaccentuée
    my $desaccent=$cols[0]; $desaccent=~s/[éèê]/e/g;
    if ($desaccent ne $cols[0]) { $tabPOS{$desaccent}=$cols[2]; }
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



# Deuxième parcours du corpus : traitement du corpus
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
    my $pos="";
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

      # Etiquetage en parties du discours (d'après les listes du CNAM avec amélioration sur les tokens inconnu commençant par une majuscule)
      if (exists $tabPOS{lc($token)}) { $pos=$tabPOS{lc($token)}; }
      elsif (length($token)>=4 && $token=~/^[A-Z]\p{L}+$/) { $pos="Nom:Propre"; }
      elsif ($token=~/^d\'$/i) { $pos="Pre"; }
      elsif ($token=~/^l\'$/i) { $pos="Det:Mas+SG"; }
      elsif ($token=~/^[[:digit:]]+$/) { $pos="Num"; }
      elsif ($token=~/^[[:punct:]]+$/) { $pos="Pct"; }
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
      if ($token ne "") {
	  push(@tabulaire,"$token\t$taille\t$interT\t$pos\t$decl\t$freq\t$rareC\t$rareV\t$soundex\t");
	  push(@labels,$tag);
      }

      # Reinitializations
      if ($fin ne "") { $tag="O"; }
      $prec=$tag;
    }
    # New line
    push(@tabulaire,"");
    push(@labels,"");
  }
  close(E);
}


# Production du tabulaire final
open(S,'>:utf8',"$sortie");
my $i=0;
foreach my $ligne (@tabulaire) {
    my $tag="";
    
    # Appel des routines en fonction du format voulu
    if ($format eq "BWEMO") { $tag=&bwemo($labels[$i-1],$labels[$i],$labels[$i+1]); }
    elsif ($format eq "BWEMO+") { $tag=&bwemoPlus($labels[$i-1],$labels[$i],$labels[$i+1]); }    
    elsif ($format eq "IO") { $tag=&io($labels[$i-1],$labels[$i],$labels[$i+1]); }
    elsif ($format eq "BIO") { $tag=&bio($labels[$i-1],$labels[$i],$labels[$i+1]); }
    elsif ($format eq "BIO2H") { $tag=&bio2h($labels[$i-1],$labels[$i],$labels[$i+1],$ligne); }
    else { $tag=&bio2($labels[$i-1],$labels[$i],$labels[$i+1]); }

    # Pas d'étiquette en l'absence de token
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

sub bwemo() {
    my ($avant,$courant,$apres)=@_;
    my $t="O";
    # - W-annotation isolée
    if (($avant eq "O" || $avant eq "") && $courant ne "O" && $courant ne "" && ($apres eq "O" || $apres eq "")) { $t="W-$courant"; }
    # - B-début d'annotation
    elsif (($avant eq "O" || $avant eq "") && $courant ne "O" && $apres ne "O" && $courant ne "" && $apres ne "") { $t="B-$courant"; }
    # - M-milieu d'annotation
    elsif ($avant eq $courant && $courant ne "O" && $courant ne "" && $apres ne "O" && $apres ne "") { $t="M-$courant"; }
    # - E-fin d'annotation
    elsif ($avant eq $courant && $courant ne "O" && $courant ne "" && ($apres eq "O" || $apres eq "") && $apres ne $courant) { $t="E-$courant"; }
    # - O le cas échéant
    else { $t="O"; }
    return $t;
}

sub bwemoPlus() {
    my ($avant,$courant,$apres)=@_;
    my $t="O";
    # - W-annotation isolée
    if (($avant eq "O" || $avant eq "") && $courant ne "O" && $courant ne "" && ($apres eq "O" || $apres eq "")) { $t="W-$courant"; }
    # - B-début d'annotation
    elsif (($avant eq "O" || $avant eq "" || $avant ne $courant) && $courant ne "O" && $apres ne "O" && $courant ne "" && $apres ne "") { $t="B-$courant"; }
    # - M-milieu d'annotation
    elsif ($avant eq $courant && $courant ne "O" && $courant ne "" && $apres ne "O" && $apres ne "") { $t="M-$courant"; }
    # - E-fin d'annotation
    elsif ($avant eq $courant && $courant ne "O" && $courant ne "" && ($apres eq "O" || $apres eq "") && $apres ne $courant) { $t="E-$courant"; }
    # O-plus
    elsif ($courant eq "O" && $apres ne "O") {
	if ($apres ne "") { $t="O-$apres"; }
	else { $t="O-EOS"; }
    }
    # - O le cas échéant
    else { $t="O"; }
    return $t;
}

sub io() {
    my ($avant,$courant,$apres)=@_;
    my $t="O";
    # - I-début/milieu/fin d'annotation
    if (($avant eq "O" || $avant eq "" || $avant ne $courant) && $courant ne "O" && $apres ne "O" && $courant ne "" && $apres ne "") { $t="I-$courant"; }
    elsif ($avant eq $courant && $courant ne "O" && $courant ne "" && $apres ne "O" && $apres ne "") { $t="I-$courant"; }
    elsif ($avant eq $courant && $courant ne "O" && $courant ne "" && ($apres eq "O" || $apres eq "")) { $t="I-$courant"; }
    # - O le cas échéant
    else { $t="O"; }
    return $t;
}

sub bio() {
    my ($avant,$courant,$apres)=@_;
    my $t="O";
    # - I-annotation isolée
    if (($avant eq "O" || $avant eq "" || $avant ne $courant) && $courant ne "O" && $courant ne "" && ($apres eq "O" || $apres eq "")) { $t="I-$courant"; }
    # - B-début d'annotation
    elsif (($avant eq "O" || $avant eq "" || $avant ne $courant) && $courant ne "O" && $apres ne "O" && $courant ne "" && $apres ne "") { $t="B-$courant"; }
    # - I-milieu/fin d'annotation
    elsif ($avant eq $courant && $courant ne "O" && $courant ne "" && $apres ne "O" && $apres ne "") { $t="I-$courant"; }
    elsif ($avant eq $courant && $courant ne "O" && $courant ne "" && ($apres eq "O" || $apres eq "") && $apres ne $courant) { $t="I-$courant"; }
    # - O le cas échéant
    else { $t="O"; }
    return $t;
}

sub bio2h() {
    my ($avant,$courant,$apres,$l)=@_;
    my $t="O";
    # - I-annotation isolée
    if (($avant eq "O" || $avant eq "" || $avant ne $courant) && $courant ne "O" && $courant ne "" && ($apres eq "O" || $apres eq "")) { $t="I-$courant"; }
    # - B-début d'annotation
    elsif (($avant eq "O" || $avant eq "" || $avant ne $courant) && $courant ne "O" && $apres ne "O" && $courant ne "" && $apres ne "") { $t="B-$courant"; }
    # - I-milieu/fin d'annotation
    elsif ($avant eq $courant && $courant ne "O" && $courant ne "" && $apres ne "O" && $apres ne "") { $t="I-$courant"; }
    elsif ($avant eq $courant && $courant ne "O" && $courant ne "" && ($apres eq "O" || $apres eq "") && $apres ne $courant) { $t="I-$courant"; }
    # - O le cas échéant
    else { $t="O"; }
    # Tête de syntagme : essai sur les verbes et les noms (dans les portions annotées), ne sont pas des têtes de syntagme
    if ($l=~/\tVer\:/ || $l=~/\tNom\:/) { $t=~s/^[A-Z]-/H-/; }
    return $t;
}
    
sub bio2() {
    my ($avant,$courant,$apres)=@_;
    my $t="O";
    # - B-début d'annotation ou annotation isolée
    if (($avant eq "O" || $avant eq "" || $avant ne $courant) && $courant ne "O" && $courant ne "" && ($apres eq "O" || $apres eq "")) { $t="B-$courant"; }
    elsif (($avant eq "O" || $avant eq "" || $avant ne $courant) && $courant ne "O" && $apres ne "O" && $courant ne "" && $apres ne "") { $t="B-$courant"; }
    # - I-milieu/fin d'annotation
    elsif ($avant eq $courant && $courant ne "O" && $courant ne "" && $apres ne "O" && $apres ne "") { $t="I-$courant"; }
    elsif ($avant eq $courant && $courant ne "O" && $courant ne "" && ($apres eq "O" || $apres eq "")) { $t="I-$courant"; }
    # - O le cas échéant
    else { $t="O"; }
    return $t;
}
