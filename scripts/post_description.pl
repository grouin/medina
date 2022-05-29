# Description meta-linguistique du contenu de fichiers annotés :
# remplacement de chaque token par sa POS et la normalisation de sa
# casse typographique (MM Mm mm), conservation des ponctuations et
# certaines valeurs numériques + abréviations de civilité,
# substitution des autres tokens.

# Objectifs : (1) à partir des fichiers *sgml générés par application
# du modèle deid, identifier des structures linguistiques partagées
# entre plusieurs documents pour aider au repérage des données
# identifiantes, (2) production d'un squelette de document à
# instancier avec des mots correspondant à chaque POS pour générer des
# documents ressemblants

# L'identification des POS se fait hors contexte dans une liste des
# formes fléchies du français. Plusieurs POS peuvent s'appliquer à la
# même forme de surface, une seule sera conservée si simplification
# (cf. fin du script), occasionnant de potentielles erreurs ("page" =
# verbe "pager" au lieu du nom "page")


# Fichier.sgml (entrée) :
#
# Nice, le <Date>28 mai 2022</Date>
# Bien Confraternellement.
# Dr <Personne>Pierre DUPONT</Personne> Page 1/1

# Fichier.desc (sortie) :
#
# xxxxx, Nom_mm <Date>Digit Nom_mm Digit</Date>
# Nom_Mm Adv_Mm.
# Dr_Mm <Personne>xxxxx xxxxx</Personne> Ver_Mm 1/1
#
# Le mot "Orsay" est absent du dictionnaire, il est remplacé par
# "xxxxx", l'abréviation "Dr" est conservée, la phrase "Bien
# Confraternellement" se compose d'un nom suivi d'un adverbe, tous
# deux commençant par une majuscule suivie de minuscules (Mm).


# perl scripts/post_description.pl fichiers/ sgml

use strict;
use utf8;

my @rep=<$ARGV[0]/*$ARGV[1]>;
my $fichierPOS="scripts/data/forme-lemme-pos.tab";
my %tabPOS=();


&recuperePOS();


foreach my $fichier (@rep) {
    open(E,'<:utf8',$fichier);
    my $sortie=$fichier; $sortie=~s/$ARGV[1]$/desc/;
    open(S,'>:utf8',$sortie);
    while (my $ligne=<E>) {
	chomp $ligne;
	# Titre de section
	if ($ligne=~/(<titre>.*<\/titre>|<section>.*<\/section>)/) { my $annot=$1; $ligne=~s/$annot/_SECTION_/; }

	# POS tagging
	my @tokens=split(/ /,$ligne);
	foreach my $token (@tokens) {
	    $token=~s/[\,\.]$//;

	    # Informations étiquetées
	    $ligne=~s/<Cp>.*?<\/Cp>/<Cp\/>/g;
	    $ligne=~s/<Ville>.*?<\/Ville>/<Ville\/>/g;

	    # Suppression des balises
	    $token=~s/<\/?(Organisation|Personne)>//;
	    # Différentes versions du token : en minuscules, désaccentué, en minuscules désaccentué
	    my $min=lc($token);
	    my $desaccent=$token; $desaccent=~s/[éèê]/e/g;
	    my $mindesaccent=lc($desaccent);
	    $token=~s/(d|j|l|m|n|s|t)(\'|’)//;
	    #$token=~s/\#//; # hashtags
	    my $casse=""; if ($token=~/^[A-Z]+$/) { $casse="\_MM"; } elsif ($token=~/^[a-zàâéèêîïôùûç]+$/) { $casse="\_mm"; } elsif ($token=~/^[A-z][a-zàâéèêîôùûç]+$/) { $casse="\_Mm"; }

	    # Forme de surface à l'identique et en minuscules
	    if (exists $tabPOS{$token}) { my $pos=$tabPOS{$token}; $ligne=~s/$token/$tabPOS{$token}$casse/g; }
	    elsif (exists $tabPOS{$min}) { my $pos=$tabPOS{$min}; $ligne=~s/$token/$tabPOS{$min}$casse/g; }
	    # Version désaccentuée
	    elsif (exists $tabPOS{$desaccent}) { my $pos=$tabPOS{$desaccent}; $ligne=~s/$token/$tabPOS{$desaccent}$casse/g; }
	    elsif (exists $tabPOS{$mindesaccent}) { my $pos=$tabPOS{$mindesaccent}; $ligne=~s/$token/$tabPOS{$mindesaccent}$casse/g; }
	    # Version avec trait d'union
	    elsif ($token=~/\-/) {
		my @elts=split(/\-/,$token);
		foreach my $elt (@elts) {
		    $elt=lc($elt);
		    if (exists $tabPOS{$elt}) { my $pos=$tabPOS{$elt}; $ligne=~s/\Q$elt\E/$tabPOS{$elt}$casse/i; } else { $ligne=~s/\Q$elt\E/xxxxx/i; }
		}
	    }
	    # Sinon substitution
	    else { if ($token!~/[[:punct:]]/) { $ligne=~s/$token/xxxxx/; }}

	    # Transformation des chiffres dans les dates : gestion de plusieurs éléments dans une date, et plusieurs dates sur une ligne
	    #if ($ligne=~/<Date>([^\<]+)<\/Date>/) {
	    while ($ligne=~/<Date>([^\<]+)<\/Date>/ && $1!~/Digit/) {
	    #while ($ligne=~/<Date>([0-9]+)<\/Date>/) {
		my $contenu=$1;
		my @elts=split(/ /,$contenu); foreach my $elt (@elts) { if ($elt=~/^\d+$/) { $ligne=~s/$elt/Digit/; }}
		my @elts=split(/\//,$contenu); foreach my $elt (@elts) { if ($elt=~/^\d+$/) { $ligne=~s/$elt/Digit/; }}
	    }
	    if ($ligne=~/<Adresse>([^\<]+)<\/Adresse>/) { my $contenu=$1; my @elts=split(/ /,$contenu); foreach my $elt (@elts) { if ($elt=~/^\d+$/) { $ligne=~s/$elt/Digit/; }}}
	    if ($ligne=~/<(Id|Telephone)>([^\<]+)<\/(Id|Telephone)>/) { my $contenu=$1; my @elts=split(/ /,$contenu); foreach my $elt (@elts) { if ($elt=~/^\d+$/) { $ligne=~s/$elt/Digit/; }}}

	    #else {warn "*** $token $desaccent ***\n";}
	}

	# Simplification des étiquettes
	#$ligne=~s/([^\s]+)\:[^\_]+\_/$1\_/g;
	$ligne=~s/(\w+)\:[^\_]+\_/$1\_/g;
	
	print S "$ligne\n";
    }
    close(E);
    close(S);
}




sub recuperePOS() {
  # Récupération des POS
  open(E,$fichierPOS) or die "Impossible d'ouvrir $fichierPOS\n";
  while (my $ligne=<E>) {
    chomp $ligne;
    my @cols=split(/\t/,$ligne);
    $tabPOS{$cols[0]}=$cols[2];
    # Ajout d'une version désaccentuée
    my $desaccent=$cols[0]; $desaccent=~s/[éèê]/e/g;
    if ($desaccent ne $cols[0]) { $tabPOS{$desaccent}=$cols[2]; }
  }
  close(E);
  # Complétion : les abbréviations sont conservées à l'identique
  $tabPOS{"Dr"}="Dr";
  $tabPOS{"Pr"}="Pr";
  $tabPOS{"M\."}="M.";
  $tabPOS{"Mme"}="Mme";
  $tabPOS{"Melle"}="Melle";
  $tabPOS{"Dre"}="Dre";
  $tabPOS{"Drs"}="Drs";
  $tabPOS{"Pre"}="Pre";
  $tabPOS{"compte-rendu"}="Nom:Mas+SG";
}
