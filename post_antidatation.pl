#!/usr/bin/perl
# $Id: 2_antidatation.pl,v 1.8 2012/05/16 15:59:57 grouin Exp grouin $

<<DOC;
Cyril Grouin - grouin@limsi.fr - Sat May 12 18:56:25 2012

Repère toutes les dates dans un document (et intervalles de dates avec
une conjonction), normalise ces dates, puis transforme ces dates en
dates fictives (en enlevant un nombre de jours aléatoirement tiré
compris entre 1 an et 4 ans) tout en respectant l\'écart temporel
entre toutes les dates d\'un même document.
perl -MCPAN -e shell ; install DateTime

La table %mois permet la correspondance entre le mois écrit en toutes
lettres et son numéro. Les accents dans les noms de mois sont
remplacés par un point. Pour gérer les cas où le chiffre 0 a été
remplacé par un O, on intègre également dans ce tableau les noms de
mois écrits avec un 0 à la place du O.

La table %corr permet la correspondance entre la date trouvée dans le
document et la date convertie par la routine datation() au format jj
mm aaaa. Si l\'année n\'est pas renseignée, l\'année d\'écriture du
document est alors celle devant être utilisée. Elle est représentée
par $anneeDefaut.

La table %fin permet la correspondance entre la date d\'origine et la
date nouvellement générée via la routine modifie().

Pour un document dans lequel on retire 925 jours à toutes les dates :
- "29.05.50" devient "16.11.47" (normalisation : 29 05 1950, epoch:
  -618364800)
- "3 avril" devient "21 septembre" (norm: 03 04 2006, epoch:
  1144022400)
- "1960" devient "1958" (norm: 31 12 1960, epoch: -284083200)
- "2 au 9 avril 1997" devient "20 au 27 septembre 1994" (norm: 02 04
  1997 au 09 04 1997, epoch: 859939200 au 860544000)
- "juillet 96" devient "janvier 94" (norm: 28 07 1996, epoch:
  838512000)

Options de lancement :
 -r <répertoire contenant les fichiers à traiter>
    (si option non renseignée, traitement du flux entrant)
 -e <extension des fichiers à traiter>
    (*.sgml si option non renseignée)
 -n <nombre de jours à retrancher>
    (tirage au hasard si non renseigné)
 -m (maintenir les balises <date> et </date> autour des antidatations effectuées)


DOC



###
# Déclaration des packages
###

use strict;
use warnings;
use utf8;
use vars qw($opt_r $opt_e $opt_n $opt_m);
use Getopt::Std;
use Time::Local;
use POSIX;



##
# Déclaration des variables
##


# Gestion des options
&getopts("r:n:e:m");
if (!$opt_r) { die "Usage :\tperl antidatation.pl -r <répertoire> [-e <extension>] [-n <nombre de jours>]\n"; }

my (@repertoire,$extension,$entree,$sortie,$log);
my ($fichier,$ligne,$nouvelle);
my ($date,%mois,%corr,%news,%epochs,%fin,%invMois,$new,$epoch,%sous,%mois3l,%invMois3l);
my $anneeDefaut=2019;
my $soustrait;
($opt_e) ? ($extension=$opt_e) : ($extension="sgml");


%mois=(
    "janvier"=>"01",
    "f.vrier"=>"02",
    "mars"=>"03",
    "avril"=>"04",
    "mai"=>"05",
    "juin"=>"06",
    "juillet"=>"07",
    "ao.t"=>"08",
    "a0.t"=>"08",
    "septembre"=>"09",
    "octobre"=>"10",
    "0ct0bre"=>"10",
    "novembre"=>"11",
    "n0vembre"=>"11",
    "d.cembre"=>"12"
    );
%invMois=(
    "01"=>"janvier",
    "02"=>"février",
    "03"=>"mars",
    "04"=>"avril",
    "05"=>"mai",
    "06"=>"juin",
    "07"=>"juillet",
    "08"=>"août",
    "09"=>"septembre",
    "10"=>"octobre",
    "11"=>"novembre",
    "12"=>"décembre"
    );



##
# Programme principal
##


# Si option -r, traitement du répertoire
if ($opt_r) {
    if (-d $opt_r) { @repertoire=<$opt_r/*$extension>; }
    else { @repertoire=($opt_r); }
    foreach $fichier (@repertoire) {
	$sortie=substr($fichier,0,length($fichier)-length($extension))."dat";
	$log=$sortie.".log";
	if (!-e $sortie) {
	    print STDERR "\tTraite $fichier, résultats dans $sortie (et suivi dans $log)\n";

	    %corr=();
	    %fin=();

	    # Pour chaque fichier, on tire un nombre compris entre 365
	    # et 1460 auquel on ajoute 365 ; correspond à un nombre de
	    # jours compris entre 1 an et 4 ans. Ce nombre - unique
	    # pour chaque fichier - sera retranché des différentes
	    # dates composant le fichier.
	    (!$opt_n) ? ($soustrait=int(rand(1095))+365) : ($soustrait=$opt_n);

	    open(E,'<:utf8',$fichier);
	    open(S,'>:utf8',$sortie);
	    while ($ligne=<E>) {
		chomp $ligne;
		$ligne=&traiteFichier($ligne);
		$ligne=&corrige($ligne);
		print S "$ligne\n";
	    }
	    close(E);
	    close(S);

	    print "DATE FINALE\tNOUVELLE\tDATE EPOCH\tNOMBRE\tCORRESPONDANCE\tORIGINE\n";
	    foreach my $date (keys %corr) { print "$fin{$date}\t$news{$date}\t$epochs{$date}\t$sous{$date}\t$corr{$date}\t$date\n"; }

	    open(L,'>:utf8',$log);
	    print L "DATE FINALE\tNOUVELLE\tDATE EPOCH\tNOMBRE\tCORRESPONDANCE\tORIGINE\n";
	    foreach my $date (keys %corr) { print L "$fin{$date}\t$news{$date}\t$epochs{$date}\t$sous{$date}\t$corr{$date}\t$date\n"; }
	    close(L);
	}
    }
}

# Sinon, traitement du flux entrant
else {
    (!$opt_n) ? ($soustrait=int(rand(1095))+365) : ($soustrait=$opt_n);
    while ($ligne=<STDIN>) {
	chomp $ligne;
	$ligne=&traiteFichier($ligne);
	$ligne=&corrige($ligne);
	print "$ligne\n";
    }
}


##
# Routines
##


sub traiteFichier() {
    $ligne=$_[0];
    $nouvelle=$ligne;

    while ($ligne=~/<date>([^<]+)<\/date>/i) {
	$date="$1";

	# Traitement particulier des dates converties en hash i2b2
	# (typiquement, une chaîne de caractères composées de plus de
	# 44 caractères). On remplace dès le départ ces hashs par la
	# mention "DATE" et on ne cherche pas à antidater ces éléments.
	if (length($date)>=44) {
	    $nouvelle=$ligne;
	    if ($opt_m) {
		$ligne=~s/<date>\Q$date\E<\/date>/DATE/i; 
		$nouvelle=~s/<date>\Q$date\E<\/date>/<date>DATE<\/date>/i; 
	    }
	    else { $ligne=~s/<date>\Q$date\E<\/date>/DATE/i; $nouvelle=$ligne; }
	    next; 
	}

	# Vérification grossière
	my $temp=$date; $temp=~s/O/0/g;
	my @cols=split(/ /,$temp);
	my $ok=1;
	foreach my $elt (@cols) {
	    if ($elt=~/^[0-9]+$/) {

		# Si dans la date on a plusieurs éléments numériques,
		# ces éléments doivent être inférieurs à 100 (un jour
		# entre 1 et 31, un mois entre 1 et 12, une année sur
		# deux chiffres) ou supérieurs à 1900 (une année sur
		# quatre chiffres).
		if (($elt>99)&&($elt<1900)) { $ok=0; }
	    }
	}

	if ($ok==1) {
	    # Normalisation des dates du document au format jj mm aaaa
	    datation($date); #foreach my $date (keys %corr) { print "$corr{$date}\t$date\n"; }

	    # Si la date a pu être normalisée (uniquement des valeurs
	    # numériques au format "jj mm aaaa"), on applique
	    # l'antidatation
	    if ($corr{$date}=~/^[\d\s]*$/) {
		# Modification des dates en conservant l'intervalle
		# temporel entre deux
		modifieDates();

		$ligne=~s/<date>$date<\/date>/$fin{$date}/gi;
		if ($opt_m) { $nouvelle=~s/<date>$date<\/date>/<date>$fin{$date}<\/date>/gi; }
		else { $nouvelle=~s/<date>$date<\/date>/$fin{$date}/gi; }
	    }

	    # Prise en compte des intervalles : jj mm aaaa au jj mm aaaa, jj au jj mm (aaaa)
	    elsif ($corr{$date}=~/\d+ (au|à) \d+/) {
		# Modification des dates en conservant l'intervalle
		# temporel entre deux
		modifieDates();

		$ligne=~s/<date>$date<\/date>/$fin{$date}/gi;
		if ($opt_m) { $nouvelle=~s/<date>$date<\/date>/<date>$fin{$date}<\/date>/gi; }
		else { $nouvelle=~s/<date>$date<\/date>/$fin{$date}/gi; }
	    }

	    # Sinon, on remplace la date par la mention textuelle
	    # "DATE" et on ne réalise aucune antidatation
	    else {
		warn "La date ($date) n'a pas pu être normalisée\n";
		$ligne=~s/<date>$date<\/date>/DATE/gi;
		if ($opt_m) { $nouvelle=~s/<date>$date<\/date>/<date>DATE<\/date>/gi; }
		else { $nouvelle=~s/<date>$date<\/date>/DATE/gi; }
	    }

	} else {
	    warn "*** Pas ok : $date\n";
	    $ligne=~s/<date>$date<\/date>/DATE/gi;
	    if ($opt_m) { $nouvelle=~s/<date>$date<\/date>/<date>DATE<\/date>/gi; }
	    else { $nouvelle=~s/<date>$date<\/date>/DATE/gi; }
	}

    }

    return $nouvelle;
}

sub datation() {
    my $date=$_[0];
    $date=~s/30.02/28.02/; # Le 30 février n'existe pas...
    $new=$date;
    $new=~s/O/0/gi;
    $new=~s/[\.\-\/]/ /g;
    $new=lc($new);
    $new=~s/1er/01/g;
    foreach my $m (keys %mois) { $new=~s/$m/$mois{$m}/; }
    my @cols=split(/ /,$new);

    # Rétablissement sur au moins deux caractères du contenu de chaque
    # élément (typiquement, les jours et mois mentionnés avec un seul
    # chiffre sont rétablis sur deux chiffres). Ce rétablissement est
    # projeté dans le tableau @cols.
    my $i=0;
    foreach my $elt (@cols) {
    	if ($elt=~/^[0-9]*$/) { if (length($elt)<2 && $elt<10) { $cols[$i]="0".$elt; } }
    	$i++;
    }


    # Si 3 éléments : jour, mois, année ; on rétablit l'année sur
    # quatre chiffres si ce n'est pas le cas avec 20 comme préfixe
    # pour une année inférieure à 15 (2000 à 2015) et le préfixe 19
    # pour les années supérieures à 15 (1916 à 1999).
    if ($#cols==2) {

	my $annee;
	if ($cols[2]<100) {                             # Si année sur deux chiffres
	    if ($cols[2]<15) { $annee="20".$cols[2]; }  # Si inférieur à 15, alors 20xx
	    else { $annee="19".$cols[2]; }              # Sinon 19xx
	} else { $annee=$cols[2]; }                     # Sinon, année sur quatre chiffres conservée

	$corr{$date}="$cols[0] $cols[1] $annee"; 

    }

    # Si 2 éléments : jour mois (si le mois est inférieur ou égal à
    # 12) ou mois année le cas contraire. On utilise l'année
    # $anneeDefaut pour représenter l'année d'écriture du document.
    elsif ($#cols==1) {

	# Le deuxième élément est supérieur à 12, donc il s'agit d'une année
	if ($cols[1]>12) {
	    my $annee;
	    if ($cols[1]<100) {                             # Si année sur deux chiffres
		if ($cols[1]<15) { $annee="20".$cols[1]; }  # Si inférieur à 15, alors 20xx
		else { $annee="19".$cols[1]; }              # Sinon 19xx
	    } else { $annee=$cols[1]; }                     # Sinon, année sur quatre chiffres conservée

	    $corr{$date}="28 $cols[0] $annee";

	}

	# Sinon, on considère que le deuxième élément est un mois
	else { $corr{$date}="$cols[0] $cols[1] $anneeDefaut"; }

    }

    # Si 1 élément : si supérieur à 1900 alors année, sinon année sur
    # deux chiffres (si supérieur à 31), jour (si supérieur à 12), et
    # mois ou jour si inférieur à 12 (impossible à discriminer). On
    # utilise l'année $anneeDefaut pour représenter l'année d'écriture
    # du document. Idéalement, il faudrait l'identifier pour la
    # réinjecter.
    elsif ($#cols==0) {

	if ($cols[0]>1900) { $corr{$date}="31 12 $cols[0]"; }
	elsif ($cols[0]>31) { $corr{$date}="31 12 19$cols[0]"; }
	elsif ($cols[0]>12) { $corr{$date}="$cols[0] 12 $anneeDefaut"; }
	else { $corr{$date}="28 $cols[0] $anneeDefaut"; } # cas où le mois est écrit en toutes lettres

    }

    # Si 4 éléments, intervalle de dates : 1 au 6 septembre
    elsif ($#cols==3) { $corr{$date}="$cols[0] $cols[3] $anneeDefaut au $cols[2] $cols[3] $anneeDefaut"; }

    # Si 5 éléments, intervalle de dates : 2 au 4 septembre 2006
    elsif ($#cols==4) {	$corr{$date}="$cols[0] $cols[3] $cols[4] au $cols[2] $cols[3] $cols[4]"; }

    # Si 6 éléments, énumération de dates : 12 13 14 et 15 juin
    elsif ($#cols==5) {	$corr{$date}="$cols[0] $cols[4] $cols[5] au $cols[3] $cols[4] $cols[5]"; }

    # Sinon, on ne sait pas traiter
    else { $corr{$date}="NIL"; }

    #print "$corr{$date}\t$new ($#cols)\t$date\n";

    return %corr;
}


sub modifieDates() {

    foreach my $date (keys %corr) {

	# S'il s'agit d'un intervalle entre deux dates
	if ($date=~/ (au|et) /) {
	    my $coord=$1;

	    # Intervalle de dates : 2 au 9 avril 1997 (format
	    # d'origine) -> 02 04 1997 au 09 04 1997 (correspondance)
	    # -> 859939200 au 860544000 (epochs)

	    my @cols=split(/ /,$corr{$date});
	    my $j1=$cols[0]; $j1=~s/^0//; if ($j1==0) { $j1++; }
	    my $j2=$cols[4]; $j2=~s/^0//; if ($j2==0) { $j2++; }
	    my $m=$cols[5]; $m=~s/^0//;
	    my $a=$cols[6];
	    my $epoch1=0;
	    my $epoch2=0;
	    my ($z1,$z2);
	    #warn "*** Intervalle : $j1 $m $a au $j2 $m $a\n";
	    if ($j1<=31 && $j2<=31 && $m<=12) {
		$epoch1 = timegm(00, 00, 00, $j1, $m-1, $a);
		$epoch2 = timegm(00, 00, 00, $j2, $m-1, $a);
		$epochs{$date}="$epoch1 $coord $epoch2";
		$z1=$epoch1-86400*$soustrait;
		$z2=$epoch2-86400*$soustrait;
		$fin{$date}="$z1 $coord $z2"; # On retranche un nb aléatoire de jours.
		#warn "*** $z1 $coord $z2\n";
	    }

	    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($z1);
	    $mon+=1; $year+=1900; if ($mon<10) { $mon="0".$mon; } if ($mday<10) { $mday="0".$mday; }
	    my ($sec2,$min2,$hour2,$mday2,$mon2,$year2,$wday2,$yday2,$isdst2) = gmtime($z2);
	    $mon2+=1; $year2+=1900; if ($mon2<10) { $mon2="0".$mon2; } if ($mday2<10) { $mday2="0".$mday2; }

	    $new="$mday $mon $year $coord $mday2 $mon2 $year2";
	    $news{$date}=$new;

	    #warn "*** $date -> $new\n";

	}

	else {
	    # Dans un premier temps, on convertit chaque date du
	    # document au format epoch (i.e., le nombre de secondes
	    # écoulées depuis le 1er janvier 1970 pour représenter
	    # cette date). Permet un calcul plus facile de
	    # l'intervalle entre deux dates.
	    my @cols=split(/ /,$corr{$date});
	    my $j=$cols[0]; $j=~s/^0//; if ($j==0) { $j++; }
	    my $m=$cols[1]; $m=~s/^0//;
	    my $a=$cols[2];
	    $epoch=0;
	    if ($j<=31 && $m<=12) {
		$epoch = timegm(00, 00, 00, $j, $m-1, $a);
		$epochs{$date}=$epoch;
		$fin{$date}=$epoch-86400*$soustrait; # On retranche un nb aléatoire de jours.
	    }

	    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($fin{$date});
	    #my $new=gmtime($fin{$date});
	    $mon+=1; $year+=1900; if ($mon<10) { $mon="0".$mon; } if ($mday<10) { $mday="0".$mday; }

	    $new="$mday $mon $year";
	    $news{$date}=$new;
	}



	# On représente la date finale dans le même format que la date
	# d'origine
	my @cols=split(/ /,$new);

	# S'il s'agit d'un intervalle de dates
	if ($new =~ / (au|et|à) /) {
	    my $coord=$1;

	    # 2 au 9 avril 1997 -> 03 02 1994 au 10 02 1994 -> 14 12
	    # 1993 au 21 12 1993 -> 14 au 21 décembre 1993
	    if ($date=~/^[0-9O]+ $coord [0-9O]+ \p{L}+ [0-9O]{4}$/) {

		# Si les deux dates sont dans le même mois, sinon on
		# indique les deux mois
		if ($cols[1]==$cols[5]) {
		    my $d=$cols[0]; if ($d<10) { $d=substr($d,1); } if ($d==1) { $d="1er"; }
		    my $d2=$cols[4]; if ($d2<10) { $d2=substr($d2,1); } if ($d2==1) { $d2="1er"; }
		    $fin{$date}="$d $coord $d2 $invMois{$cols[5]} $cols[6]"; 
		}

		# 30 septembre au 07 octobre 1998 <- 30 09 1998 au 07
		# 10 1998 <- 979344000 au 979948800 <- 836 <- 13 01
		# 2001 au 20 01 2001 <- 13 au 20 janvier 2001
		else {
		    my $d=$cols[0]; if ($d<10) { $d=substr($d,1); } if ($d==1) { $d="1er"; }
		    my $d2=$cols[4]; if ($d2<10) { $d2=substr($d2,1); } if ($d2==1) { $d2="1er"; }
		    $fin{$date}="$d $invMois{$cols[1]} $coord $d2 $invMois{$cols[5]} $cols[6]"; 
		}

	    } elsif ($date=~/^[0-9O]+ $coord [0-9O]+ \p{L}+$/) {

		# Si les deux dates sont dans le même mois, sinon on
		# indique les deux mois
		if ($cols[1]==$cols[5]) {
		    my $d=$cols[0]; if ($d<10) { $d=substr($d,1); } if ($d==1) { $d="1er"; }
		    my $d2=$cols[4]; if ($d2<10) { $d2=substr($d2,1); } if ($d2==1) { $d2="1er"; }
		    $fin{$date}="$d $coord $d2 $invMois{$cols[5]}"; 
		}

		# 30 septembre au 07 octobre 1998 <- 30 09 1998 au 07
		# 10 1998 <- 979344000 au 979948800 <- 836 <- 13 01
		# 2001 au 20 01 2001 <- 13 au 20 janvier 2001
		else {
		    my $d=$cols[0]; if ($d<10) { $d=substr($d,1); } if ($d==1) { $d="1er"; }
		    my $d2=$cols[4]; if ($d2<10) { $d2=substr($d2,1); } if ($d2==1) { $d2="1er"; }
		    $fin{$date}="$d $invMois{$cols[1]} $coord $d2 $invMois{$cols[5]}"; 
		}

	    } else {
		$fin{$date}=$new;
	    }
	    $sous{$date}=$soustrait; # Nombre de jours retranchés à cette date

	    #warn "*** $date -> $new -> $fin{$date}\n";

	} else {

            # 2000
	    if ($date=~/^[0-9O]{4}$/) { $fin{$date}=$cols[2]; }
	    # 88
	    elsif ($date=~/^[0-9O]{2}$/) { $fin{$date}=substr($cols[2],2); }
	    # 22.12.2000
	    elsif ($date=~/^[0-9O]{1,2}\.[0-9O]{1,2}\.[0-9O]{4}$/) { $fin{$date}="$cols[0].$cols[1].$cols[2]"; }
	    # 22.12
	    elsif ($date=~/^[0-9O]{1,2}\.[0-9O]{2}$/) { $fin{$date}="$cols[0].$cols[1]"; }
	    # 22.12.00
	    elsif ($date=~/^[0-9O]{1,2}\.[0-9O]{1,2}\.[0-9O]{2}$/) { $fin{$date}="$cols[0].$cols[1].".substr($cols[2],2); }
	    # 22/12/2000
	    elsif ($date=~/^[0-9O]{1,2}\/[0-9O]{1,2}\/[0-9O]{4}$/) { $fin{$date}="$cols[0]\/$cols[1]\/$cols[2]"; }
	    # 22/12/00
	    elsif ($date=~/^[0-9O]{1,2}\/[0-9O]{1,2}\/[0-9O]{2}$/) { $fin{$date}="$cols[0]\/$cols[1]\/".substr($cols[2],2); }
	    # 22 décembre 2000
	    elsif ($date=~/^[0-9O]{1,2}(er|) \p{L}+ [0-9O]{4}$/) {
		my $d=$cols[0]; if ($d<10) { $d=substr($d,1); } if ($d==1) { $d="1er"; }
		$fin{$date}="$d $invMois{$cols[1]} $cols[2]"; 
	    }
	    # 22 décembre
	    elsif ($date=~/^[0-9O]{1,2}(er|) \p{L}+$/) {
		my $d=$cols[0]; if ($d<10) { $d=substr($d,1); } if ($d==1) { $d="1er"; }
		$fin{$date}="$d $invMois{$cols[1]}";
	    }
	    # décembre 2000
	    elsif ($date=~/^\p{L}+ [0-9O]{4}$/) { $fin{$date}="$invMois{$cols[1]} $cols[2]"; }
	    # décembre 96
	    elsif ($date=~/^\p{L}+ [0-9O]{2}$/) { $fin{$date}="$invMois{$cols[1]} ".substr($cols[2],2); }
	    # décembre
	    elsif ($date=~/^\p{L}+$/) { $fin{$date}="$invMois{$cols[1]}"; }
	    else { $fin{$date}=$new; }

	    #print "$fin{$date}\t$new\t$epoch\t$corr{$date}\t$date\n";
	    $sous{$date}=$soustrait; # Nombre de jours retranchés à cette date

	}


    }

}

sub corrige() {
    $ligne=$_[0];

    # "d'" devant un mois qui commence par une consonne
    $ligne=~s/d\'\s?(janvier|février|mars|mai|juin|juillet|septembre|novembre|décembre)/de $1/gi;

    # "de" devant un mois qui commence par une voyelle
    $ligne=~s/de (avril|août|octobre)/d\'$1/gi;

    return $ligne;
}
