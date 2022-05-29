#!/usr/bin/perl

# Affiche les séquences de faux positifs et de faux négatifs avec
# contexte précédent (ligne précédente sans erreur) et suivant (ligne
# suivante sans erreur) à partir d'un fichier de prédictions au format
# tabulaire avec schéma d'annotation BIO

# Usage : perl differences.pl fichier.tab fp/fn/fpfn

# Auteur : Cyril Grouin, novembre 2019.

use strict;

my $fichier=$ARGV[0];
my $type=$ARGV[1]; if (!$ARGV[1]) { $type="fpfn"; }
my @lignes=();
my @fp=();
my @fn=();

open(E,$fichier);
while (my $ligne=<E>) {
    chomp $ligne;
    push(@lignes,$ligne);
}
close(E);

my $i=0;
foreach my $ligne (@lignes) {
    my @cols=split(/\t/,$ligne);
    # Faux positifs
    if (($cols[$#cols]!~/^O/) && ($cols[$#cols-1]=~/^O/) && $type=~/fp/) {
	my $j=$i-1; $fp[$j]="$j\t$lignes[$j]\n" if ($fp[$j] ne "");
	$fp[$i]="$i\t$ligne\n";
	my $k=$i+1; $fp[$k]="$k\t$lignes[$k]\n" if ($fp[$k] ne "");
    }
    # Faux négatifs
    if (($cols[$#cols]=~/^O/) && ($cols[$#cols-1]!~/^O/) && $type=~/fn/) {
	my $j=$i-1; $fn[$j]="$j\t$lignes[$j]\n" if ($fn[$j] ne "");
	$fn[$i]="$i\t$ligne\n";
	my $k=$i+1; $fn[$k]="$k\t$lignes[$k]\n" if ($fn[$k] ne "");
    }
    $i++;
}

print "Faux positifs :\n-------------\n";
my $prec=0;
foreach my $ligne (sort @fp) {
    my @cols=split(/\t/,$ligne);
    if ($cols[0]!=$prec+1 && $ligne ne "") { print "\n"; }
    print "$ligne";
    $prec=$cols[0];
}

print "\n\nFaux négatifs :\n-------------\n";
my $prec=0;
foreach my $ligne (sort @fn) {
    my @cols=split(/\t/,$ligne);
    if ($cols[0]!=$prec+1 && $ligne ne "") { print "\n"; }
    print "$ligne";
    $prec=$cols[0];
}

