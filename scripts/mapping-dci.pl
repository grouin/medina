# Effectue un mapping des segments-clés de la DCI sur des fichiers. On
# affiche la classe thérapeutique, sauf pour les anticorps monoclonaux
# pour lesquels on affiche la classe pharmacologique. Si la classe
# thérapeutique est vide, on prend la classe pharmaco. On travaille
# sur les segments-clés en anglais et en français ; pour la version en
# anglais, on mémorise également la version sans "e" final (bien que
# l'OMS indique le "e" final : e.g., -floxacine).

# Envisager ce script uniquement sur les lignes étiquetées "drugs" par
# un CRF.

# perl mapping-dci.pl ../../../../projet-Cress/scripts/europeen.csv 1 europeen.dci

use strict;

my $fichier=$ARGV[0]; # Fichier à traiter
my $col=$ARGV[1];     # Colonne à traiter dans le fichier
my $sortie=$ARGV[2];  # Fichier de sortie
my $defaut="Unknown"; # Valeur affichée par défaut si aucune classe trouvée


# Fichier tabulaire contenant les DCI, format : segment-clé (EN),
# segment-clé (FR), classe pharmaco, classe thérapeutique, DCI
# (spécialités entre parenthèses), chapitre ATC (?), classe
# pharmaco-thérapeutique
my $dci="data/dci.tsv";
my %segments=();
my $i=0;


###
# Récupération des segments-clés de la DCI et classes thérapeutiques associées

open(E,'<:utf8',$dci);
while (my $ligne=<E>) {
    chomp $ligne;
    my ($segmentEN,$segmentFR,$pharmaco,$thera,$specialites,$chapitre,$pharther,$remarque)=split(/\t/,$ligne);
    my $classe=$pharther; $thera=~s/\, /\//g;
    ($thera ne "") ? ($classe=$thera) : ($classe=$pharmaco);
    $classe=$pharther if ($pharmaco eq "");

    if ($segmentEN ne "") {
	# Plusieurs segments dans la même cellule (séparés par une barre oblique), on fragmente
	if ($segmentEN=~/\//) {
	    # Segments-clés en français
	    my @cols2=split(/\//,$segmentFR);
	    foreach my $seg (@cols2) { $segments{$seg}=$classe; $i++; }
	    # Segments-clés en anglais, y compris la version sans "e" final
	    my @cols2=split(/\//,$segmentEN);
	    foreach my $seg (@cols2) { $segments{$seg}=$classe; $i++; if ($seg=~/e$/) { my $t=$seg; chop $t; $segments{$t}=$classe; } }
	}
	# Un seul segment-clé par cellule
	else {
	    # Pour les anti-corps monoclonaux, on conserve la classe pharmacologique
	    if ($segmentEN=~/mab$/) { $segments{$segmentEN}=$pharmaco; }
	    # Pour le reste, on conserve la classe thérapeutique
	    else { $segments{$segmentEN}=$classe; $segments{$segmentFR}=$classe; }
	    # Pour le segment-clé en anglais, on conserve également la version sans "e" final
	    if ($segmentEN=~/e$/) { my $t=$segmentEN; chop $t; $segments{$t}=$classe; } 
	    $i++;
	}
    }
}
close(E);
warn "$i segments obtenus\n";
#foreach my $seg (sort keys %segments) { print "$seg\t$segments{$seg}\n"; }


###
# Traitement du fichier principal

open(E,'<:utf8',$fichier);
open(S,'>:utf8',$sortie);
while (my $ligne=<E>) {
    chomp $ligne;
    my @cols=split(/\t/,$ligne);
    my $contenu=$cols[$col];

    # Plusieurs noms de médicament
    if ($contenu=~/[\+\,]/) {
	my @cols2=split(/[\+\,]/,$contenu);
	my $affichage="";
	for (my $i=0;$i<=$#cols2;$i++) {
	    my $medicament=$cols2[$i];
	    # Plusieurs mots pour un seul médicament
	    if ($medicament=~/ /) {
		my @cols3=split(/ /,$medicament);
		for (my $i=0;$i<=$#cols3;$i++) {
		    #warn "-- Traite $cols3[$i] parmi $medicament\n";
		    my $contenu2=$cols3[$i]; $contenu2=~s/^\s+//; $contenu2=~s/\s+$//;
		    my $classes=&identifieClasses($contenu2); $affichage.="$classes\, ";
		}
	    }
	    else {
		my $contenu2=$medicament; $contenu2=~s/^\s+//; $contenu2=~s/\s+$//;
		my $classes=&identifieClasses($contenu2); $affichage.="$classes\, ";
	    }
	}
	$affichage=~s/\, $//; $affichage=~s/\, $defaut//g; $affichage=~s/$defaut\, //g; if ($affichage eq "") { $affichage=$defaut; }
	print S "$contenu\t$affichage\n";
    }
    # Un seul nom de médicament
    else { 
	# Plusieurs mots pour un seul médicament
	if ($contenu=~/ /) {
	    my @cols2=split(/ /,$contenu);
	    my $affichage="";
	    for (my $i=0;$i<=$#cols2;$i++) {
		#warn "-- Traite $cols2[$i] parmi $contenu\n";
		my $contenu2=$cols2[$i]; $contenu2=~s/^\s+//; $contenu2=~s/\s+$//;
		# Un nom se terminant par "-a" est peut-être de l'espagnol ou de l'italien : francisation
		if ($contenu2=~/a$/) {
		    my $classes=&identifieClasses($contenu);
		    if ($classes ne $defaut) { $affichage.="$classes\, "; }
		    else { $contenu2=~s/a$/e/; my $classes=&identifieClasses($contenu2); $affichage.="$classes\, "; }
		}
		else { my $classes=&identifieClasses($contenu2); $affichage.="$classes\, "; }		
	    }
	    $affichage=~s/\, $//; $affichage=~s/\, $defaut//g; $affichage=~s/$defaut\, //g; if ($affichage eq "") { $affichage=$defaut; }
	    print S "$contenu\t$affichage\n";
	}
	else {
	    # Si un mot se termine par "-a", on vérifie qu'il ne
	    # s'agit pas d'abord d'un mot réel en DCI, si la classe
	    # reste nulle, on essaie une francisation
	    if ($contenu=~/a$/) {
		my $classes=&identifieClasses($contenu);
		if ($classes ne $defaut) { print S "$contenu\t$classes\n"; }
		else { $contenu=~s/a$/e/; my $classes=&identifieClasses($contenu); print S "$contenu\t$classes\n"; }
	    } else { my $classes=&identifieClasses($contenu); print S "$contenu\t$classes\n"; }
	}
    }
}
close(E);
close(S);


###
# Routines

sub identifieClasses() {
    # Identifie les classes des médicaments en cherchant la présence
    # de chaque élément passé en argument parmi les segments-clés
    my $cont=lc($_[0]);
    my $cl="";
    my $k=0;

    # On parcourt le mot :

    # Du dernier au premier caractère
    for (my $j=length($cont);$j>1;$j--) {
	my $mot=substr($cont,0,$j); my $prefixe="$mot\-"; my $suffixe="\-$mot"; my $affixe="\-$mot\-";
	if (exists $segments{$suffixe} && $cl eq "") { $cl="$segments{$suffixe}"; $k++; }
	elsif (exists $segments{$prefixe} && $cl eq "") { $cl="$segments{$prefixe}"; $k++; }
	elsif (exists $segments{$affixe} && $cl eq "") { $cl="$segments{$affixe}"; $k++; }
    }
    # Du premier au dernier caractère (permet de considérer les
    # suffixes les plus longs d'abord)
    for (my $j=0;$j<length($cont);$j++) {
    	my $mot=substr($cont,$j); my $prefixe="$mot\-"; my $suffixe="\-$mot"; my $affixe="\-$mot\-";
    	if (exists $segments{$suffixe} && $cl eq "") { $cl="$segments{$suffixe}"; $k++; }
    	elsif (exists $segments{$prefixe} && $cl eq "") { $cl="$segments{$prefixe}"; $k++; }
    	elsif (exists $segments{$affixe} && $cl eq "") { $cl="$segments{$affixe}"; $k++; }
    }

    if ($cl eq "") { $cl=$defaut; }
    return $cl;
}
