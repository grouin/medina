# Crée un lexique de noms de patients, à partir des noms de patient
# présents dans les noms de fichiers (12345_NOM_Prénom_67890.txt ;
# 12345_NOM_NOM_Prénom_67890.txt ; 12345_NOM_PrénomPrénom_67890.txt),
# pour utilisation en post-traitement ; deux colonnes séparées par une
# tabulation : classe, portion textuelle

# perl scripts/creeLexiqueDepuisFichiers.pl input/ >lexique.txt

use strict;
my $chemin=$ARGV[0];
my @rep=<$chemin/*>;
my %lexique=();

foreach my $fichier (@rep) {
    my ($nom,$prenom)=("","");
    if ($fichier=~/\d+\_(.*)\_\d+\_\d+/) {
	my $schema=$1; $schema=~s/\_?\(.*\)//;
	my @tokens=split(/\_/,$schema);
	# Valable tant que le(s) nom(s) sont en capitales et le(s)
	# prénom(s) en minuscules avec majuscule initiale
	foreach my $token (@tokens) {
	    if ($token=~/^\p{Lu}+$/) { $nom.="$token "; }
	    else {
	    	$prenom.="$token ";
	    	if ($prenom=~/^([A-Z][a-zàâçéèêëîïôöùû]+)([A-Z][a-zàâçéèêëîïôöùû]+)\s?$/) {
	    	    my ($debut,$fin)=($1,$2);
	    	    $prenom=~s/$debut$fin/$debut\-$fin/;
	    	}
	    }
	}
    }
    $nom=~s/\s?$//; $prenom=~s/\s?$//;
    print "Personne\t$prenom $nom\n";
    print "Personne\t$nom $prenom\n";
    $prenom=~s/\-/ \- /g;
    print "Personne\t$prenom $nom\n";
    print "Personne\t$nom $prenom\n";
}
