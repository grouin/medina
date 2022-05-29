#!/usr/bin/perl

# Pour l'entraînement d'un modèle sur de nouvelles données, en
# reprenant le modèle distribué (modele-deid), il faut convertir les
# labels des nouvelles annotations absents du corpus ayant servi à
# produire le modèle distribué. Ce script remplace les annotations :
#
# - B-URL M-URL et E-URL en W-URL (même si la tokénisation a découpé
#   une URL en plusieurs segments)
# - M-Age et M-Cp en E-Age et E-Cp (même si les portions Age et Cp se
#   composent, à juste titre, de plusieurs éléments : deux ans et
#   demi, soixante-huit ans, de 20 à 30 ans)
#
# Le script écrase le fichier passé en entrée pour produire un fichier
# du même nom en sortie :
# $ perl scripts/poursuiteEntrainement.pl tab_reduc.zero
#
# Poursuivre l'entraînement Wapiti avec la commande suivante :
# $ wapiti train -a rprop -p config/config_zero.tpl tab_reduc.zero -m modele-deid modele-enrichi

# Auteur : Cyril Grouin, avril 2022


use strict;
use utf8;

my $fichier=$ARGV[0];
my @lignes=();
my %inconnus=();

# Lecture et modification des annotations inconnues du modèle
# distribué
open(E,'<:utf8',$fichier) or die "Impossible d'ouvrir $fichier\n";
while (my $ligne=<E>) {
    chomp $ligne;
    $ligne=~s/\t[BME]-URL$/\tW-URL/; # W-URL uniquement
    $ligne=~s/\tM-(Age|Cp)$/\tE-$1/; # E-Age ou E-Cp
    $ligne=&verification($ligne);
    push(@lignes,$ligne);
}
close(E);

# Production du nouveau tabulaire (même nom)
open(S,'>:utf8',$fichier);
foreach my $ligne (@lignes) { print S "$ligne\n"; }
close(S);

foreach my $label (sort keys %inconnus) { warn "Label $label inconnu remplacé par O\n"; }


# Vérification qu'il ne reste pas de label inconnu du modèle distribué
sub verification() {
    my $l=shift();
    my @cols=split(/\t/,$l);
    my $label=$cols[$#cols];
    if ($l ne "" && $label!~/([BWEMO]-Adresse|[BWEO]-Age|[BWEO]-Cp|[BWEMO]-Date|[BWEMO]-Id|[BWEMO]-Lieu|[BWEMO]-Organisation|[BWEMO]-Personne|[BWEMO]-Telephone|[BWEMO]-Ville|O|O-EOS|[OW]-Pays|[OW]-URL)$/) {
	$inconnus{$label}++;
	$l=~s/\t$label$/\tO/;
    }
    return $l;
}


    
