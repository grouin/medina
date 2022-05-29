# Vérification des tabulaires produits avant création d'un modèle CRF.
# Objectif de mise en évidence des erreurs de format explicatives de
# futures erreurs Wapiti.
# - pas même nombre de colonnes
# - contenu vide entre deux colonnes : \s\s
# - présence d'espaces au lieu de \t
# - une seule grosse séquence
# - contenu hétérogène par colonne ~ décalage
# - imbrication d'annotations (présence de balises </label> et <label> parmi les tokens)


# perl scripts/zero_alignement.pl fichiers/
# perl scripts/zero_tabulaire.pl fichiers/ tag tab_rapide BWEMO+
# perl scripts/pre_verification-tabulaire.pl tab_rapide


use strict;

my $fichier=$ARGV[0];
my $i=0;
my %nbCol=();
my %colErr=();

open(E,$fichier);
print "Analyse du fichier \"$fichier\"\n\n";
while (my $ligne=<E>) {
    chomp $ligne;
    
    # Colonne vide entre deux tabulations (plusieurs espaces ne posent pas de problème)
    if ($ligne=~/\t\s*\t/) { my $aff=$ligne; $aff=~s/\t\s*\t/##############/g; print "- colonne vide (ligne $i) :\n\t$aff\n\n"; }

    # Présence de balises ouvrantes ou fermantes + erreur d'offsets : indice d'annotations imbriquées
    if ($ligne=~/<\/[^>]+>/) { my $aff=$ligne; print "- annotation résiduelle + erreur offset (ligne $i) :\n\t$aff\n\n"; }

    # Erreur d'offsets uniquement
    elsif ($ligne=~/^\d+\-\-\d+/) { my $aff=$ligne; print "- erreur offset (ligne $i) :\n\t$aff\n\n"; }

    my @cols=split(/\s+/,$ligne);
    $nbCol{$#cols}++; $colErr{$#cols}.="$i ";
    $i++;
}
close(E);

# Vérification du nombre total de colonnes, soit 0, soit n ; pas plus de deux valeurs
my $j=0;
my $liste;
my $max=0;
foreach my $nb (sort keys %nbCol) {
    if ($nbCol{$nb}<10) { my $nl=$colErr{$nb}; $nl=~s/\s+$//; $liste.="\t- $nb colonnes ($nbCol{$nb} lignes : vérifier les lignes $nl)\n"; }
    else { $liste.="\t- $nb colonnes ($nbCol{$nb} lignes)\n"; }
    $j++;
    if ($nb>$max) { $max=$nb; }
}
$liste=~s/\, $//; $liste=~s/\-1 colonnes/ligne vide/; $liste=~s/\(1 lignes/\(1 ligne/g;

# Colonnes manquantes
open(E,$fichier);
my $i=0;
while (my $ligne=<E>) {
    chomp $ligne;
    my @cols=split(/\s+/,$ligne);
    if ($#cols<$max && $#cols>0 && $ligne!~/\t\t/) { my $aff=$ligne; print "- colonne manquante + décalage (ligne $i) : $#cols colonnes identifiées au lieu de $max colonnes (nombre maximum constaté)\n\t$aff\n\n"; }
    $i++;
}
close(E);

if ($j>2) { print "- nombre incorect de colonnes dans le tabulaire (avec potentiellement des colonnes manquantes) :\n$liste\n"; }
if ($j==1) { print "- une seule grosse séquence (possible oubli des sauts de lignes entre documents/phrases)\n\n"; }
