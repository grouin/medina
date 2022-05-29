# Homogénéise les étiquettes dans un tabulaire pour éviter les
# doublons dans le cas où différents corpus annotés proposent des
# catégories proches (différences de casse typographique et de nombre)

# L'homogénéisation met chaque étiquette avec une majuscule initiale,
# le reste en minuscule ; une table de correspondance permet de
# remplacer les étiquettes (passage du pluriel au singulier,
# utilisation d'un acronyme, etc.)

# Ce script est appliqué après la production du tabulaire global
# (scripts/zero_tabulaire.pl) et de la réduction du sur-apprentissage
# (scripts/zero_supprimeO.pl), pour produire le tabulaire final qui
# servira à l'apprentissage :
#
# perl scripts/homogeneise-tags.pl tab_reduc.zero tab_final.zero

# Auteur : Cyril Grouin, février 2022.

use strict;

my ($fichier,$sortie)=@ARGV;
my $i=0;
my %corr=(
    "lieux"=>"Lieu",
    "organisations"=>"Organisation",
    "personnes"=>"Personne",
    "signe-symptome"=>"Sosy"
);

open(E,$fichier);
open(S,">$sortie");
while (my $ligne=<E>) {
    chomp $ligne;
    if ($ligne=~/\-(\w+)$/) {
	my $old=$1;
	if (exists $corr{$old}) { $ligne=~s/\-$old$/\-$corr{$old}/; }
	my $tag=uc(substr($old,0,1)).substr($old,1);
	$ligne=~s/\-$old$/\-$tag/;
    }
    print S "$ligne\n";
    $i++;
    warn "$i\n" if ($i=~/00$/);
}
close(E);
close(S);
