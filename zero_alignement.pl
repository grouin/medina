#!/usr/bin/perl

# Intègre dans le texte sous forme de balises ouvrantes et fermantes
# les annotations existantes au format BRAT. Gestion correcte des
# annotations imbriquées et discontinues.

# Auteur : Cyril Grouin, novembre 2019.

use strict;
use utf8;

my @rep=<$ARGV[0]/*txt>;

foreach my $fichier (@rep) {
  # Réinitialisations tableau du contenu du fichier et compteur de
  # caractè!res
  my @contenu=();
  my $i=0;
  
  open(E,'<:utf8',$fichier);
  while (my $ligne=<E>) {
    # Segmentation en caractères et stockage de ces caractères
    my @cars=split(//,$ligne);
    foreach my $car (@cars) {
      push(@contenu,$car);
      $i++;
    }
  }
  close(E);

  # Récupération des annotations associées et stockage par taille
  # croissante des portions annotées (gestion des imbrications
  # facilitée)
  $fichier=~s/txt$/ann/;
  my %tri=();
  my $k=0;
  open(E,'<:utf8',$fichier);
  while (my $ligne=<E>) {
    chomp $ligne;
    # Annotation d'entités
    if ($ligne=~/^T/) {
      my @cols=split(/\t/,$ligne);
      my $taille=length($cols[2]);
      while (exists $tri{$taille}) { $taille+=$k; }
      $tri{$taille}=$ligne;
      $k++;
    }
  }
  close(E);

  # Gestion des annotations
  foreach my $cle (sort keys %tri) {
    my $ligne=$tri{$cle};
    if ($ligne=~/^T/) {
      my @cols=split(/\t/,$ligne);
      # Annotations non discontinues
      if ($cols[1]!~/\;/) {
	my ($classe,$debut,$fin)=split(/ /,$cols[1]);
	# Ajout des balises ouvrantes et fermantes autour des caractères de début et de fin
	$contenu[$debut]="<$classe>$contenu[$debut]"; $contenu[$fin-1].="<\/$classe>";
      } else {
	# Annotations discontinues
	my ($classe,$debut,$milieu,$fin)=split(/ /,$cols[1]);
	my ($fin1,$debut2)=split(/\;/,$milieu);
	$contenu[$debut]="<$classe>$contenu[$debut]"; $contenu[$fin1-1].="<\/$classe>";
	$contenu[$debut2]="<$classe>$contenu[$debut2]"; $contenu[$fin-1].="<\/$classe>";
      }
    }
  }

  # Affichage
  $fichier=~s/ann$/tag/;
  my @balises=();
  open(S,'>:utf8',"$fichier");
  my $ligne="";
  for (my $j=0;$j<=$i+1;$j++) { $ligne.=$contenu[$j]; }

  # Gestion des ouvertures/fermetures : stockage des balises ouvrantes
  # présentes sur la ligne
  my $ligneBalisee=$ligne; my $balise="";
  while ($ligneBalisee=~/<[^>\s]+>/) {
    if ($ligneBalisee=~/<([^\/>\s]+)>/) { $balise=$1; push(@balises,$balise); }
    $ligneBalisee=~s/<$balise>//; $ligneBalisee=~s/<\/$balise>//;
  }
  # Pour chaque balise ouvrante, vérification de la fermeture des
  # balises dans l'ordre inverse d'ouverture. Opérationnel mais pas
  # robuste
  for (my $i=0;$i<=$#balises;$i++) {
    # Si la balise ouverte est fermée sans autre balise ouvrante
    # entre, on retire du tableau cette balise
    if ($ligne=~/<$balises[$i]>[^<]*?<\/$balises[$i]>/) { shift(@balises); }
    else {
      # Cas ABAB -> ABBA
      while ($ligne=~/<$balises[$i]>[^<]*?<$balises[$i+1]>[^<]*?<\/$balises[$i]>[^<]*?<\/$balises[$i+1]>/) {
	$ligne=~s/<\/$balises[$i]>([^<]*?)<\/$balises[$i+1]>/<\/$balises[$i+1]>$1<\/$balises[$i]>/;
      }
      # Cas ABBCAC -> ABBCCA
      while ($ligne=~/<$balises[$i]>[^<]*?<$balises[$i+1]>[^<]*?<\/$balises[$i+1]>[^<]*?<$balises[$i+2]>[^<]*?<\/$balises[$i]>[^<]*?<\/$balises[$i+2]>/) {
	$ligne=~s/<\/$balises[$i]>([^<]*?)<\/$balises[$i+2]>/<\/$balises[$i+2]>$1<\/$balises[$i]>/;
      }
      # Cas ABCBAC
      while ($ligne=~/<$balises[$i]>[^<]*?<$balises[$i+1]>[^<]*?<$balises[$i+2]>[^<]*?<\/$balises[$i+1]>[^<]*?<\/$balises[$i]>[^<]*?<\/$balises[$i+2]>/) {
	$ligne=~s/<\/$balises[$i+1]>([^<]*?)<\/$balises[$i]>([^<]*?)<\/$balises[$i+2]>/<\/$balises[$i+2]>$1<\/$balises[$i+1]>$2<\/$balises[$i]>/;
      }
      # Cas ABCBCDAD -> ABCCBDDA
      while ($ligne=~/<$balises[$i]>[^<]*?<$balises[$i+1]>[^<]*?<$balises[$i+2]>[^<]*?<\/$balises[$i+1]>[^<]*?<\/$balises[$i+2]>[^<]*?<$balises[$i+3]>[^<]*?<\/$balises[$i]>[^<]*?<\/$balises[$i+3]>/) {
	$ligne=~s/<\/$balises[$i+1]>([^<]*?)<\/$balises[$i+2]>/<\/$balises[$i+2]>$1<\/$balises[$i+1]>/;
	$ligne=~s/<\/$balises[$i]>([^<]*?)<\/$balises[$i+3]>/<\/$balises[$i+3]>$1<\/$balises[$i]>/;
      }
      shift(@balises);
    }
  }
  print S "$ligne";
  close(S);
}
