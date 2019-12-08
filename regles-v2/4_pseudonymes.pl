#!/usr/bin/perl

<<DOC;
Cyril Grouin - grouin@limsi.fr - Sat Jun 2 22:04:47 2012

	4_pseudonymes.pl

Format d\'entree : les fichiers *.med balisés par Medina ou les
fichiers *.dat antidatés.

Format de Sortie : les informations comprises entre balises <nom> et
<prenom> sont remplacées par des informations génériques.

DOC



###
# Déclaration des packages
###

use strict;
use open ':utf8';
use vars qw($opt_r $opt_e);
use Getopt::Std;



##
# Déclaration des variables
##


# Gestion des options
&getopts("r:e:");
if (!$opt_r) { die "Usage :\tperl 4_pseudonymes.pl -r <répertoire> -e <extension med/dat>\n"; }

my (@rep,$ext,$entree,$sortie,$ligne);
my (%indexN,%indexP,%corrN,%corrP);

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



(!$opt_e) ? ($ext="med") : ($ext=$opt_e);
@rep=<$opt_r/*.$ext>;

foreach $entree (@rep) {

    # Le fichier de sortie est d'extension *.pse
    $sortie=substr($entree,0,length($entree)-3)."pse";

    warn "4_p> traite $entree et produit $sortie\n";


    # Première étape : on relève tous les noms et prénoms présents
    # dans le document et on stocke ces noms et prénoms dans des
    # tables de hachage dédiées.

    open(E,$entree);
    while ($ligne=<E>) {
	while ($ligne=~/<nom>([^<]+)<\/nom>/) {
	    my $nom=$1;
	    $indexN{$nom}++;
	    $ligne=~s/<nom>$nom<\/nom>/$nom/g; 
	}
	while ($ligne=~/<prenom>([^<]+)<\/prenom>/) {
	    my $prenom=$1;
	    $indexP{$prenom}++;
	    $ligne=~s/<prenom>$prenom<\/prenom>/$prenom/g; 
	}
    }
    close(E);


    # Deuxième étape : on trie alphabétiquement chaque occurrence de
    # nom et on attribue le nom correspondant d'après ce numéro
    # d'ordre. Ainsi, la première occurrence alphabétique des noms de
    # famille dans le document devient Martin, la seconde devient
    # Bernard, la troisième devient Dubois, etc. Idem avec les
    # prénoms.

    my $i=1;
    foreach $ligne (sort keys %indexN) {
	$indexN{$ligne}=$corrN{$i};
	$i++;
    }

    $i=1;
    foreach $ligne (sort keys %indexP) {
	my $modification;
	# Si le prénom est présent sous forme d'une initiale, on prend
	# l'initiale du prénom correspondant
	if ($ligne=~/^[A-Z]\.$/) { $modification=substr($corrP{$i},0,1)."."; } else { $modification=$corrP{$i}; }

	$indexP{$ligne}=$modification;
	$i++;
    }


    # Troisième étape : on effectue les remplacements dans le document
    # et on produit le document de sortie ainsi modifié ; les noms et
    # prénoms créés remplacent les balises.

    open(E,$entree);
    open(S,">$sortie");
    while ($ligne=<E>) {
	chomp $ligne;

	foreach my $occurrence (sort keys %indexN) {
	    $ligne=~s/<nom>$occurrence<\/nom>/$indexN{$occurrence}/g;
	}
	foreach my $occurrence (sort keys %indexP) {
	    $ligne=~s/<prenom>$occurrence<\/prenom>/$indexP{$occurrence}/g;
	}

	# On imprime la ligne ainsi traitée
	print S "$ligne\n";

    }
    close(E);
    close(S);
}

