#!/usr/bin/perl

# Pseudonymise les fichiers de prédictions en remplaçant les portions
# annotées, soit par des substituts (catégories Personne et
# Telephone), soit par le nom de la catégorie (liste des catégories
# passées en argument de l'option -c). L'option -m permet de conserver
# des balises ouvrantes et fermantes autour des pseudonymes (Personne,
# Ville) et informations qui auront été marquées mais non changées
# (Adresse, Code postal, etc.).

# Usage : perl post_pseudonymization.pl -r répertoire/ -e extension [-c Personne,Telephone] [-m]

# Auteur : Cyril Grouin, décembre 2019.


# Exemple : M. <Personne>Jean Valjean</Personne> au <Telephone>01-99-88-77-66</Telephone>
#
# Pour appliquer le script sur les fichiers d'extension *dat du
# répertoire corpus/jorf/test/ et masquer les prédictions de Téléphone
# en les remplaçant par le nom de la catégorie :
#
# perl post_pseudonymization.pl -r corpus/jorf/test/ -e dat -c Telephone
# - output : M. Marc Berger au <Telephone />
#
# Si on souhaite remplacer les prédictions de Telephone par des
# numéros aléatoires, on retire la catégorie Telephone de l'option -c
#
# perl post_pseudonymization.pl -r corpus/jorf/test/ -e dat
# - output : M. Marc Berger au 01-90-85-57-88


use strict;
use utf8;
use vars qw($opt_r $opt_e $opt_c $opt_m);
use Getopt::Std;

&getopts("r:e:c:m");
if (!$opt_r) { die "Usage :\tperl post_pseudonymization.pl -r <directory> -e <extension sgml/dat> [-c categories,to,be,masked] [-m]\n"; }

my $listePrenoms="scripts/data/prenoms-fr.lxq";
my $listeNoms="scripts/data/noms-fr.lxq";
my $listeVilles="scripts/data/villes-fr.lxq";
my $refPrenoms=&recupereListe($listePrenoms);
my $refNoms=&recupereListe($listeNoms);
my $refVilles=&recupereListe($listeVilles);
my $refNomsVilles=&recupereIndex($listeVilles);

my $ext; (!$opt_e) ? ($ext="sgml") : ($ext=$opt_e);
my @rep=<$opt_r/*.$ext>;

my (%indexNoms,%indexVilles,%corr,%corrV);
my @categories=split(/\,/,$opt_c);



###
# Programme

# Extraction des prédictions réalisées pour les catégories Personne et
# Lieu (villes)
foreach my $entree (@rep) {
  open(E,'<:utf8',$entree);
  while (my $ligne=<E>) {
    # Noms de personne
    while ($ligne=~/<Personne>([^<]+)<\/Personne>/i) {
      my $personne=$1;
      $indexNoms{$personne}++;
      $ligne=~s/<Personne>$personne<\/Personne>/$personne/gi;
    }
    # Noms de ville : encadrées de balises Lieu, on ne conserve que
    # les annotations identifiées dans la liste des villes de l'INSEE.
    # Les autres annotations Lieu sont considérées comme n'étant pas
    # des villes et font l'objet d'un autre traitement.
    $ligne=~s/<Lieu>/<Ville>/g; $ligne=~s/<\/Lieu>/<\/Ville>/g;
    while ($ligne=~/<Ville>([^<]+)<\/Ville>/i) {
      my $ville=$1; my $villeLC=substr($ville,0,1).substr(lc($ville),1);
      if (exists ${$refNomsVilles}{$ville}) { $indexVilles{$ville}++; $ligne=~s/<Ville>$ville<\/Ville>/$ville/gi; }
      elsif (exists ${$refNomsVilles}{$villeLC}) { $indexVilles{$ville}++; $ligne=~s/<Ville>$ville<\/Ville>/$ville/gi; }
      else { $ligne=~s/<Ville>/<Lieu>/; $ligne=~s/<\/Ville>/<\/Lieu>/; }
    }
  }
  close(E);
}

# Attribution de correspondances valables sur l'ensemble du corpus
foreach my $personne (sort keys %indexNoms) {
  my ($prenom,$nom)=&recuperePrenomNom($personne);

  # Tirage aléatoire de prénom et nom dans les listes existantes
  my $alea=int(rand(keys %{$refPrenoms}));
  my $nouveauPrenom=${$refPrenoms}{$alea};
  $alea=int(rand(keys %{$refNoms}));
  my $nouveauNom=${$refNoms}{$alea};
  
  # Génération des variantes (prénom et nom en majuscules, prénom en
  # minuscules et nom en majuscules, prénom et nom en minuscules avec
  # initiale en majuscule, versions avec initiale du prénom suivie
  # d'un point ou directement de l'espace)
  &PRENOMNOM($prenom,$nom,$nouveauPrenom,$nouveauNom);
  &PrenomNOM($prenom,$nom,$nouveauPrenom,$nouveauNom);
  &PNOM($prenom,$nom,$nouveauPrenom,$nouveauNom);
  &PrenomNom($prenom,$nom,$nouveauPrenom,$nouveauNom);
  &PNom($prenom,$nom,$nouveauPrenom,$nouveauNom);
}

foreach my $ville (sort keys %indexVilles) {
  # Tirage aléatoire de prénom et nom dans les listes existantes
  my $alea=int(rand(keys %{$refVilles}));
  my $nouvelleVille=${$refVilles}{$alea};
  $corrV{$ville}=$nouvelleVille;
}


# Remplacement des informations et production des fichiers de sortie
foreach my $entree (@rep) {
  # Output file extension
  my $sortie=substr($entree,0,length($entree)-3)."pse";
  warn "Produit $sortie\n";

  open(E,'<:utf8',$entree);
  open(S,'>:utf8',$sortie);
  while (my $ligne=<E>) {
    # Catégories à masquer : la portion annotée est remplacée par le
    # nom de la catégorie ("le <Organisation>CNRS</Organisation>" ->
    # "le Organisation")
    if (!$opt_m) { foreach my $categorie (@categories) { $ligne=~s/<$categorie>[^<]+<\/$categorie>/<$categorie \/>/g; }}

    # Catégories à pseudonymiser
    # - Personne
    while ($ligne=~/<Personne>([^<]+)<\/Personne>/i) {
      my $personne=$1;
      if (exists $corr{$personne}) {
	#warn "identifie $personne\n";
	if ($opt_m) { $ligne=~s/<Personne>$personne<\/Personne>/\[Personne\]$corr{$personne}\[\/Personne\]/gi; }
	else { $ligne=~s/<Personne>$personne<\/Personne>/$corr{$personne}/gi; }
      } else {
	warn "manque : $personne\n";
	if ($opt_m) { $ligne=~s/<Personne>$personne<\/Personne>/\[Personne\]$corr{$personne}\[\/Personne\]/gi; }
	else { $ligne=~s/<Personne>$personne<\/Personne>/$personne/gi; }
      }
    }
    # - Telephone (numéros français)
    while ($ligne=~/<Telephone>([^<]+)<\/Telephone>/i) {
      my $telephone=$1;
      # Conservation du préfixe géographique du téléphone, le reste
      # est tiré au hasard. Le troisième caractère sert de séparateur
      my $prefixe=substr($telephone,0,2);
      my $separateur=substr($telephone,2,1);
      my @couples=split(/$separateur/,$telephone);
      my $nouveau=$telephone;
      foreach my $couple (@couples) {
	next if ($couple eq $prefixe);
	my $alea=int(rand(25)); my $modif=$couple;
	($couple+$alea<100) ? ($modif+=$alea) : ($modif-=$alea);
	if ($modif<10) { $modif="0".$modif; }
	$nouveau=~s/$couple/$modif/;
      }
      print "$telephone -> $nouveau\n";
      if ($opt_m) { $ligne=~s/<Telephone>$telephone<\/Telephone>/\[Telephone\]$nouveau\[\/Telephone\]/; }
      else { $ligne=~s/<Telephone>$telephone<\/Telephone>/$nouveau/; }
    }
    # - Lieu (villes uniquement)
    $ligne=~s/<Lieu>/<Ville>/g; $ligne=~s/<\/Lieu>/<\/Ville>/g;
    while ($ligne=~/<Ville>([^<]+)<\/Ville>/i) {
      my $ville=$1;
      if (exists $corrV{$ville}) {
	if ($opt_m) { $ligne=~s/<Ville>$ville<\/Ville>/\[Ville\]$corrV{$ville}\[\/Ville\]/gi; }
	else { $ligne=~s/<Ville>$ville<\/Ville>/$corrV{$ville}/gi; }
      }
      $ligne=~s/<Ville>/<Lieu>/; $ligne=~s/<\/Ville>/<\/Lieu>/;
    }

    # Les autres catégories (pas explicitement marquées comme devant
    # être masquées, et pour lesquelles un traitement de
    # pseudonymisation n'a pas été prévu) sont également masquées
    if (!$opt_m) {
      while ($ligne=~/<([^>\/]+)>[^<]+<\/[^>\/]+>/) {
        my $tag=$1;
        $ligne=~s/<$tag>[^<]+<\/$tag>/<$tag \/>/g;
      }
    }

    # Rétablissement balises [label] => <label>
    if ($opt_m) {
      while ($ligne=~/\[(\/?[^\]]+)\]/) { my $tag=$1; $ligne=~s/\[$tag\]/\<$tag\>/; }
    }
    
    # Affichage ligne modifiée
    print S $ligne;
  }
  close(E);
  close(S);
}


###
# Routines

sub recupereListe() {
  my $liste=shift;
  my %cl=();
  my $i=0;
  open(E,'<:utf8',$liste);
  while (my $ligne=<E>) {
    chomp $ligne;
    $cl{$i}=$ligne;
    $i++;
  }
  close(E);
  return \%cl;
}

sub recupereIndex() {
  my $liste=shift;
  my %cl=();
  open(E,'<:utf8',$liste);
  while (my $ligne=<E>) {
    chomp $ligne;
    $cl{$ligne}++;
  }
  close(E);
  return \%cl;
}

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

sub PRENOMNOM() {
  my ($prenomReel,$nomReel,$substitutPrenom,$substitutNom)=@_;
  
  $substitutNom=uc($substitutNom); $substitutPrenom=uc($substitutPrenom);
  my $cle=uc("$prenomReel $nomReel");
  if ($prenomReel ne "") { $corr{$cle}="$substitutPrenom $substitutNom"; } else { $corr{$cle}="$substitutNom"; }
  $corr{$prenomReel}=$substitutPrenom;
  #print "-(1) $cle/$substitutPrenom $substitutNom\n";
}

sub PrenomNOM() {
  my ($prenomReel,$nomReel,$substitutPrenom,$substitutNom)=@_;
  my $prenomReelNormalise=&minusculesMajusculeInitiale($prenomReel);
  my $substitutPrenomNorm=&minusculesMajusculeInitiale($substitutPrenom);

  my $cle; if ($prenomReel ne "") { $cle=$prenomReelNormalise." ".uc($nomReel); } else { $cle=uc($nomReel); }
  
  $corr{$cle}="$substitutPrenomNorm $substitutNom";
  #print "-(2) $cle/$substitutPrenomNorm $substitutNom\n";
  my $cle2=substr($prenomReel,0,1).lc(substr($prenomReel,1));
  $corr{$cle2}="$substitutPrenomNorm";
}

sub PNOM() {
  my ($prenomReel,$nomReel,$substitutPrenom,$substitutNom)=@_;

  my $ip=substr($substitutPrenom,0,1);
  my $cle; if ($prenomReel ne "") { $cle=substr($prenomReel,0,1)." ".uc($nomReel); } else { $cle=uc($nomReel); }
  
  $corr{$cle}="$ip $substitutNom";
  $corr{$cle}="$ip\. $substitutNom";
  #print "-(3) $cle/$ip $substitutNom\n";

  $cle=uc($nomReel);
  $corr{$cle}="$substitutNom";
  #print "-(4) $cle/$substitutNom\n";
}

sub PrenomNom() {
  my ($prenomReel,$nomReel,$substitutPrenom,$substitutNom)=@_;
  my $prenomReelNormalise=&minusculesMajusculeInitiale($prenomReel);
  my $nomReelNormalise=&minusculesMajusculeInitiale($nomReel);

  my $cle; if ($prenomReel ne "") { $cle=$prenomReelNormalise." ".$nomReelNormalise; } else { $cle=$nomReelNormalise; }
  $corr{$cle}="$substitutPrenom $substitutNom";
  #print "-(5) $cle/$substitutPrenom $substitutNom\n";
}

sub PNom() {
  my ($prenomReel,$nomReel,$substitutPrenom,$substitutNom)=@_;
  my $nomReelNormalise=&minusculesMajusculeInitiale($nomReel);

  my $ip=substr($substitutPrenom,0,1);
  my $cle; if ($prenomReel ne "") { $cle=substr($prenomReel,0,1)." ".$nomReelNormalise; } else { $cle=$nomReelNormalise; }
  $corr{$cle}="$ip $substitutNom";
  $corr{$cle}="$ip\. $substitutNom";
  #print "-(6) $cle/$ip $substitutNom\n";
}
