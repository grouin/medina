#!/usr/bin/perl

# A partir du tabulaire produit pour construire le modèle Wapiti,
# conserve uniquement les lignes contenant un préfixe d'annotation
# (pour les différents formats possible : IO BIO BWEMO), ainsi que les
# /n/ lignes étiquetées O qui précèdent ou qui suivent une ligne
# annotée

# Usage : perl zero_supprimeO.pl tabulaire tailleContexteConservé

# Auteur : Cyril Grouin, juillet 2014


###
# Déclaration des packages et variables

use strict;

my $fichier=$ARGV[0];
my $n=$ARGV[1]; if (!$ARGV[1]) { $n=6; }

my %lignes;
my $i=1000000;
my %deja=();
my $contenu="";


###
# Programme principal


# Stockage des lignes dans une table de hachage : à chaque ligne
# correspond un identifiant numérique unique

open(E,$fichier);
while (my $ligne=<E>) {
  chomp $ligne;
  $lignes{$i}=$ligne;
  $i++;
}
close(E);

# Conservation des lignes étiquetées et des /n/ lignes qui précèdent
# et qui suivent les lignes annotées

foreach $i (sort keys %lignes) {
  my @cols=split(/\t/,$lignes{$i});
  my $flag=0;

  # Si la ligne porte une annotation, on affiche la ligne
  if ($cols[$#cols]=~/^[BIWEMH]/) {
    $contenu.="$lignes{$i}\n" if (!exists $deja{$i});
    $deja{$i}++;
  }

  # Sinon, on vérifie que dans les /n/ lignes qui précèdent ou qui
  # suivent, on rencontre une ligne porteuse d'annotation. Dans ce
  # cas, on affiche la ligne courante (c'est alors une ligne O qui
  # correspond à un contexte gauche ou droit d'une ligne annotée)
  elsif ($cols[$#cols]=~/^O/) {

    # On recherche une ligne annotée dans les /n/ lignes qui précèdent
    for (my $j=0;$j<=$n;$j++) {
      my $somme=$i-$j;
      my @cols2=split(/\t/,$lignes{$somme});
      if ($cols2[$#cols2]=~/^[BIWEMH]/) { $flag=$somme; }
    }
    if ($flag>0) {
      $contenu.="$lignes{$i}\n" if (!exists $deja{$i});
      $deja{$i}++;
      $flag=0;
    }

    # On recherche une ligne annotée dans les /n/ lignes qui suivent
    for (my $j=0;$j<=$n;$j++) {
      my $somme=$i+$j;
      my @cols2=split(/\t/,$lignes{$somme});
      if ($cols2[$#cols2]=~/^[BIWEMH]/) { $flag=$somme; }
    }
    if ($flag>0) {
      $contenu.="$lignes{$i}\n" if (!exists $deja{$i});
      $deja{$i}++;
      $flag=0;
    }

  }

  # Si on est sur une ligne O et que dans les /n/ lignes qui précèdent
  # ou qui suivent on ne trouve pas de ligne portant une annotation,
  # on n'affiche rien, hormis un saut de ligne pour ne pas générer une
  # seule séquence
  else { if ($flag==0) { $contenu.="\n"; } }

}

$contenu=~s/\n{2,}/\n\n/g;
print $contenu;
