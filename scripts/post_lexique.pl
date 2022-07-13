#!/usr/bin/perl

# A partir du fichier tabulaire de prédictions Wapiti (extension
# .wap), complète la dernière colonne par l'annotation des séquences
# de 1 à 6 tokens présentes dans le lexique (deux colonnes séparées
# par une tabulation : classe et expression mono/poly-lexicale) et
# dans le tabulaire, ssi la séquence n'a pas déjà été partiellement
# annotée par Wapiti (évite d'annoter "Orsay" dans "Hôpital d'Orsay"
# avec "Hôpital d'" comme Organisation et "Orsay" comme Ville). Dans
# certains cas, il peut être préféré de corriger des prédictions en
# les remplaçant (prévoir un deuxième lexique pour remplacements
# imposés ?).

# - lexique.tab (prévoir la tokénisation, pas pratique...) :
# Ville   Orsay
# Examen  séquences pulmonaires et cérébrales
# Titre   Compte - rendu d' imagerie nucléaire

# perl post_lexique.pl -l lexique.tab -r ./ -e wap -s out


use strict;
use vars qw($opt_r $opt_e $opt_s $opt_l);
use Getopt::Std;
&getopts("r:e:s:l:");

my @rep=<$opt_r/*$opt_e>;
my $colToken=1;

my ($numToken,$numCol,$lastCol)=(0,0,0);
my $lexique=$opt_l; #"lexique.tab";
my @LEX=();
my %LEXcorr=();



###
# Récupération du contenu du lexique

open(E,$lexique) or die "Impossible d'ouvrir $lexique\n";
while (my $ligne=<E>) {
    chomp $ligne;
    $ligne=lc($ligne);
    $ligne=~s/ /\_/g;
    my @cols=split(/\t/,$ligne);
    push(@LEX,$cols[1]);
    $LEXcorr{quotemeta($cols[1])}=$cols[0];
}
close(E);



###
# Traitement

foreach my $fichier (@rep) {
    my $sortie=$fichier; $sortie=~s/$opt_e$/$opt_s/;
    warn "735> produit $sortie à partir de $fichier\n";

    my @global=();
    my $numToken=0;

    ###
    # Récupération du contenu du fichier

    open(E,$fichier);
    while (my $ligne=<E>) {
	# Pour chaque ligne du tabulaire, segmentation en colonnes,
	# pour chaque colonne, stockage dans un tableau
	chomp $ligne;

	# Pour les lignes non vides, on enregistre le contenu de chaque colonne
	if ($ligne ne "") {
	    my @cols=split(/\t/,$ligne);
	    $lastCol=$#cols;
	    for (my $numCol=0;$numCol<=$lastCol;$numCol++) { $global[$numToken][$numCol]=$cols[$numCol]; }
	    $numToken++;
	}
	# Pour les lignes vides, on imprime du vide pour conserver la segmentation d'origine entre séquences
	else {
	    for (my $numCol=0;$numCol<=$lastCol;$numCol++) { $global[$numToken][$numCol]=""; }
	    $numToken++;
	}
    }
    close(E);
    my $total=$numToken;


    ###
    # Application du contenu des listes

    $numToken=0;
    foreach my $ligne (@global) {
	my $texte="";

	# Six tokens
	my $token=quotemeta($global[$numToken-5][$colToken])."_".quotemeta($global[$numToken-4][$colToken])."_".quotemeta($global[$numToken-3][$colToken])."_".quotemeta($global[$numToken-2][$colToken])."_".quotemeta($global[$numToken-1][$colToken])."_".quotemeta($global[$numToken][$colToken]);
	my $sequenceTag=$global[$numToken-5][$lastCol].$global[$numToken-4][$lastCol].$global[$numToken-3][$lastCol].$global[$numToken-2][$lastCol].$global[$numToken-1][$lastCol].$global[$numToken][$lastCol];
	if ((grep/^$token$/i,@LEX) && ($sequenceTag=~/(^O+$|^O+\-EOS$)/)) {
	    $token=lc($token);
	    my $claff=""; if (exists $LEXcorr{$token}) { $claff=uc(substr($LEXcorr{$token},0,1)).substr($LEXcorr{$token},1); }
	    $global[$numToken-5][$lastCol]="B-".$claff;
	    $global[$numToken-4][$lastCol]="M-".$claff;
	    $global[$numToken-3][$lastCol]="M-".$claff;
	    $global[$numToken-2][$lastCol]="M-".$claff;
	    $global[$numToken-1][$lastCol]="M-".$claff;
	    $global[$numToken][$lastCol]="E-".$claff;
	}

	# Cinq tokens
	my $token=quotemeta($global[$numToken-4][$colToken])."_".quotemeta($global[$numToken-3][$colToken])."_".quotemeta($global[$numToken-2][$colToken])."_".quotemeta($global[$numToken-1][$colToken])."_".quotemeta($global[$numToken][$colToken]);
	my $sequenceTag=$global[$numToken-4][$lastCol].$global[$numToken-3][$lastCol].$global[$numToken-2][$lastCol].$global[$numToken-1][$lastCol].$global[$numToken][$lastCol];
	if ((grep/^$token$/i,@LEX) && ($sequenceTag=~/(^O+$|^O+\-EOS$)/)) {
	    $token=lc($token);
	    my $claff=""; if (exists $LEXcorr{$token}) { $claff=uc(substr($LEXcorr{$token},0,1)).substr($LEXcorr{$token},1); }
	    $global[$numToken-4][$lastCol]="B-".$claff;
	    $global[$numToken-3][$lastCol]="M-".$claff;
	    $global[$numToken-2][$lastCol]="M-".$claff;
	    $global[$numToken-1][$lastCol]="M-".$claff;
	    $global[$numToken][$lastCol]="E-".$claff;
	}

	# Quatre tokens
	my $token=quotemeta($global[$numToken-3][$colToken])."_".quotemeta($global[$numToken-2][$colToken])."_".quotemeta($global[$numToken-1][$colToken])."_".quotemeta($global[$numToken][$colToken]);
	my $sequenceTag=$global[$numToken-3][$lastCol].$global[$numToken-2][$lastCol].$global[$numToken-1][$lastCol].$global[$numToken][$lastCol];
	if ((grep/^$token$/i,@LEX) && ($sequenceTag=~/(^O+$|^O+\-EOS$)/)) {
	    $token=lc($token);
	    my $claff=""; if (exists $LEXcorr{$token}) { $claff=uc(substr($LEXcorr{$token},0,1)).substr($LEXcorr{$token},1); }
	    $global[$numToken-3][$lastCol]="B-".$claff;
	    $global[$numToken-2][$lastCol]="M-".$claff;
	    $global[$numToken-1][$lastCol]="M-".$claff;
	    $global[$numToken][$lastCol]="E-".$claff;
	}

	# Trois tokens
	my $token=quotemeta($global[$numToken-2][$colToken])."_".quotemeta($global[$numToken-1][$colToken])."_".quotemeta($global[$numToken][$colToken]);
	my $sequenceTag=$global[$numToken-2][$lastCol].$global[$numToken-1][$lastCol].$global[$numToken][$lastCol];
	if ((grep/^$token$/i,@LEX) && ($sequenceTag=~/(^O+$|^O+\-EOS$)/)) {
	    $token=lc($token);
	    my $claff=""; if (exists $LEXcorr{$token}) { $claff=uc(substr($LEXcorr{$token},0,1)).substr($LEXcorr{$token},1); }
	    $global[$numToken-2][$lastCol]="B-".$claff;
	    $global[$numToken-1][$lastCol]="M-".$claff;
	    $global[$numToken][$lastCol]="E-".$claff;
	}

	# Deux tokens
	my $token=quotemeta($global[$numToken-1][$colToken])."_".quotemeta($global[$numToken][$colToken]);
	my $sequenceTag=$global[$numToken-1][$lastCol].$global[$numToken][$lastCol];
	if ((grep/^$token$/i,@LEX) && ($sequenceTag=~/(^O+$|^O+\-EOS$)/)) {
	    $token=lc($token);
	    my $claff=""; if (exists $LEXcorr{$token}) { $claff=uc(substr($LEXcorr{$token},0,1)).substr($LEXcorr{$token},1); }
	    $global[$numToken-1][$lastCol]="B-".$claff;
	    $global[$numToken][$lastCol]="E-".$claff;
	}

	# Un seul token
	my $token=quotemeta($global[$numToken][$colToken]);
	my $sequenceTag=$global[$numToken][$lastCol];
	if ((grep/^$token$/i,@LEX) && ($sequenceTag=~/(^O+$|^O+\-EOS$)/)) {
	    $token=lc($token);
	    my $claff=""; if (exists $LEXcorr{$token}) { $claff=uc(substr($LEXcorr{$token},0,1)).substr($LEXcorr{$token},1); }
	    $global[$numToken][$lastCol]="W-".$claff;
	}

	$numToken++; # Numéro de token (permet de gérer les séquences de tokens)
    }


    ###
    # Affichage

    $numToken=0;
    open(S,">$sortie");
    foreach my $ligne (@global) {
	my $texte="";
	for (my $numCol=0;$numCol<=$lastCol;$numCol++) {
	    $texte.=$global[$numToken][$numCol];
	    $texte.="\t";
	}
	chomp $texte;
	$texte=~s/\t$//;

	if ($global[$numToken][$colToken] ne "") { print S "$texte\n"; }
	else { print S "\n"; }

	$numToken++; # Numéro de token (permet de gérer les séquences de tokens)
    }
    close(S);
}
