#!/usr/bin/perl

<<DOC;
Cyril Grouin - grouin@limsi.fr - Sat Jun 2 15:14:04 2012

	5_hyperonymes.pl

Format d\'entree : soit les fichiers *.med balisés par Medina, soit
les fichiers *.dat antidatés (réalisés à partir des fichiers *.med
balisés), soit encore les fichiers *.pse avec pseudonymes (produits à
partir des fichiers *.dat antidatés).

Format de Sortie : les informations balisées sont remplacées par des
hyperonymes (les dates et pseudonymes sont conservés si le script est
appliqué sur des fichiers d\'extension *.dat ou *.pse ; en revanche,
toutes les données seront anonymisées si le script est directement
appliqué sur les sorties balisées *.med).

DOC



###
# Déclaration des packages
###

use strict;
use warnings;
use open ':utf8';
use vars qw($opt_r $opt_e);
use Getopt::Std;



##
# Déclaration des variables
##


# Gestion des options
&getopts("r:e:");
if (!$opt_r) { die "Usage :\tperl 5_hyperonymes.pl -r <répertoire> -e <extension med/dat>\n"; }

my (@rep,$ext,$entree,$sortie,$ligne);

(!$opt_e) ? ($ext="med") : ($ext=$opt_e);
@rep=<$opt_r/*.$ext>;

foreach $entree (@rep) {

    # Le fichier de sortie est d'extension *.sgml
    $sortie=substr($entree,0,length($entree)-3)."sgml";

    warn "5_h> traite $entree et produit $sortie\n";

    open(E,$entree);
    open(S,">$sortie");
    while ($ligne=<E>) {
	chomp $ligne;

	# Si on travaille sur des fichiers *.dat (fichiers antidatés)
	# ou *.pse (fichiers avec noms et prénoms génériques), les
	# dates ont déjà été modifiées par rapport à l'originale, on
	# conserve donc ces informations.
	if ($ext eq "dat" || $ext eq "pse") { $ligne=~s/<\/?date>//g; }

	# Deux fois la phase de correction/remplacement pour gérer les
	# cas d'inclusions de balises.
	corrige($ligne);
	remplace($ligne);
	corrige($ligne);
	remplace($ligne);

	# On imprime la ligne ainsi traitée
	print S "$ligne\n";

    }
    close(E);
    close(S);
}

sub corrige {

    $ligne=$_[0];

    # Si la ligne contient, à l'intérieur d'un passage balisé, une
    # information déjà remplacée par une balise, on supprime cette
    # balise (possible erreur de Medina).

    if ($ligne=~/<[^>\/]+>[^<]+(<[^\/]+ \/>)[^<]+<\/[^>]+>/) {
	my $pb=$1;
	$ligne=~s/$pb//g;
    }

    return $ligne;

}

sub remplace {

    $ligne=$_[0];

    # On remplace toutes les informations sur la ligne
    while ($ligne=~/<([^>\/]+)>([^<]+)<\/[^>]+>/) {
	my ($bal,$info)=($1,$2);
	$ligne=~s/<$bal>$info<\/$bal>/<$bal \/>/g;
    }
    return $ligne;
}
