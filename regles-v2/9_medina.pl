#!/usr/bin/perl

# MEDINA : MEDical INformation Anonymization ; Cyril Grouin, octobre
# 2013.

# Logiciel d'annotation automatique de fichiers textuels, fondé sur
# une grammaire externe définie par l'utilisateur. Fichier de
# configuration "config" obligatoire (chemin d'accès aux lexiques,
# dictionnaire et grammaires).

# Lancement : perl 9_medina.pl -r corpus/ -e txt
#             cat fichier.txt | perl 9_medina.pl

# Options :
# -r répertoire (traitement du flux courant si inutilisée)
# -e extension des fichiers à traiter (tous les fichiers si non renseignée)
# -c (affichage des éléments traités pour contrôle)
# -g (annotation de tout ce qui n'est pas dans le dictionnaire en "hors")
# -d (annotation de ce qui n'est pas dans le dictionnaire en "hors",
#     les autres champs conservent leur balise)
# -t "mot/expression" (affiche les lignes qui contiennent ce mot lors
#    du traitement)
# -p (propagation des annotations à la place de la balise "hors")
# -x (les lexiques ne sont pas projetés sur l'ensemble de la ligne :
#     ne gère pas les expressions composées de plusieurs mots "Premier
#     ministre" mais uniquement les mots simples présents dans les
#     listes "Président" ; permet de réduire le temps de traitement)

# Les règles de la grammaire utilisateur reposent sur les expressions
# régulières implémentées dans PERL : [] *+? \. \d\w. En particulier,
# la gestion de la portion à annoter figure entre parenthèses (la
# première parenthèse ouvrante débute la portion à annoter).
# - Le parenthésage fonctionne en l'absence de contexte, ou avec
# présence d'un contexte gauche (qui ne doit pas figurer dans la
# portion annotée) : "_PATIENT (_CAPINI_SPACE_CAPINI)" permet de
# conserver le déclencheur hors de la portion annotée.
# - En présence d'un contexte droit, le parenthésage doit
# obligatoirement être remplacé par la syntaxe !~ et ~! de manière à
# conserver dans le texte le contexte droit : "!~_CHIFFRE{2,}~! SA".
# - Cette syntaxe peut également être utilisée en l'absence de
# contexte ou en présence d'un contexte gauche. Les parenthèses se
# révèlent néanmoins plus lisibles pour un humain.

# Problème de boucle sur le symbole pourcentage ou le point (en fin
# d'abréviation comptant plusieurs points) réglé par le remplacement
# de la limite de patron "\b" par "\s". Le look behind négatif permet
# de gérer correctement les frontières de substitution.

# Problème de généralisation dans l'application des patrons (si
# généralisation, toutes les occurrences de "président" ou "hier" sont
# annotées, y compris à l'intérieur des mots "présidentielles" et
# "Thierry" ; si pas de généralisation, seule la première occurrence
# sera annotée, éventuellement avec autant d'annotations que
# d'occurrences du schéma "président" ou "hier" selon les réglages
# effectués). Problème a priori réglé :
#
# echo "Le président Thierry s'est déclaré hier candidat aux présidentielles avec le président du Sénat." | perl 9_medina.pl -x -c

# Création d'un exécutable (à faire pour chaque plateforme Mac/Unix ;
# pour un exécutable Unix 32-bits, il est nécessaire d'installer un
# compilateur Perl 32-bits, possible sur une machine 64-bits) :
# pp -f Bleach -o medina_unix.exe 9_medina.pl



###
# Librairies et variables

use locale;
use strict;
use vars qw($opt_r $opt_e $opt_c $opt_d $opt_g $opt_t $opt_p $opt_x);
use Getopt::Std;
#use open ':utf8';
use utf8;

&getopts("r:e:cdgt:px");
#if (!$opt_r) { die "Usage :\tperl 9_medina.pl -r répertoire -e extension\n"; }

my (%dico,%lexique,%grammaire,%anti_dico,$schema);
my (%balises,%types,@motifs,%deja);
my @dossier=<$opt_r/*$opt_e>;
my $balise_defaut="hors";


###
# Programme

configuration();
traite();


###
# Sous-programmes

sub configuration() {
    #warn "9> configuration et récupération des ressources linguistiques\n";

    open(E,"config") or die "Impossible de configurer le programme (fichier config manquant)\n";
    my %fichiers=();
    my $i=0;

    # Stockage des balises associées à chaque type, et du chemin
    # d'accès à chaque lexique
    while (my $ligne=<E>) {
	chomp $ligne;
	if ($ligne=~/^fichier=(.*)$/) { $schema=$1; }
	if ($ligne!~/^\/\// && $ligne ne "") {
	    my @cols=split(/\t/,$ligne);
	    my @cols2=split(/\:/,$cols[1]);
	    $fichiers{"$cols2[0]$i"}=$cols2[1];
	    $balises{"$cols2[0]$i"}=$cols[0];
	    $types{$cols[0]}++;
	    $i++;
	}
    }
    close(E);
    $types{$balise_defaut}++;

    # Stockage des ressources linguistiques : dictionnaire, lexiques
    # (autant que le souhaite l'utilisateur) et grammaire utilisateur.
    foreach my $fichier (sort keys %fichiers) {
	if ($fichier=~/dictionnaire/) { $lexique{"dico"}=&liste("$fichiers{$fichier}",1); }
	if ($fichier=~/lexique/) { $lexique{"$fichier"}=&liste("$fichiers{$fichier}",4); }
	if ($fichier=~/grammaire/) { $grammaire{"$fichier"}=&tabulaire("$fichiers{$fichier}"); }
    }
}

sub liste() {
    # Stocke le contenu des lexiques (un élément par ligne) dans une
    # table de hachage, à l'identique et intégralement en majuscules.

    my $fichier=$_[0];
    my $seuil=$_[1];
    my %tableau=();

    #open(E,'<:utf8',$fichier) or die "Impossible d'ouvrir $fichier\n";
    open(E,$fichier) or die "Impossible d'ouvrir $fichier\n";
    #warn "   . $fichier\n";
    while (my $ligne=<E>) {
	chomp $ligne;
	if (length($ligne)>=$seuil && $ligne!~/^\/\//) {
	    $tableau{$ligne}++;              # Version d'origine dans le lexique
	    $tableau{uc($ligne)}++;          # Version en capitales
	    my $capini=uc(substr($ligne,0,1)).substr($ligne,1);
	    $tableau{$capini}++;             # Version avec capitale initiale
	    if ($ligne!~/[sx]$/i) { $ligne.="s"; $tableau{$ligne}++; } # Version au pluriel
	}
    }
    close(E);

    return \%tableau;
}

sub tabulaire() {
    # Stocke le contenu de la grammaire de l'utilisateur (deux
    # colonnes : balise et motif cherché) dans une table de hachage.

    my $fichier=$_[0];
    my %tableau=();
    my %correspondance=();

    open(E,$fichier);
    #warn "   . $fichier\n";
    while (my $ligne=<E>) {
	chomp $ligne;

	# Pour les lignes non vides et hors commentaires (// Commentaire)
	if ($ligne!~/^\/\// && $ligne ne "") {
	  $ligne=~s/\s*\/\/.*$//g; # Suppression des commentaires sur la ligne

	    # Récupération des variables définies par l'utilisateur
	    # ($VARIABLE) ; les éléments de ces variables sont
	    # également stockés dans un anti-dictionnaire.
	    if ($ligne=~/^\$(?<VARIABLE>[^\t]+)\t(?<EREG>.*)$/) {
		$correspondance{$+{VARIABLE}}=$+{EREG};
		my $ereg=$+{EREG}; $ereg=~s/^\(//; $ereg=~s/\)$//; $ereg=~s/\s+\:?$//;
		my @cols9=split(/\|/,$ereg);
		foreach my $elt9 (@cols9) {
		    if ($elt9!~/\d/ && $elt9!~/[[:punct:]]/) { $anti_dico{$elt9}++; }
		}
	    }

	    # Récupération des règles
	    else {

	      # Si motif !~xxx~!, ce qui figure entre cette syntaxe
	      # constitue le motif. Sinon, la première parenthèse
	      # ouvrante correspond au motif à traiter dans la
	      # grammaire
	      if ($ligne=~/\!\~/) { $ligne=~s/\!\~/\(\?<MOTIF>/; $ligne=~s/\~\!(.*)/\)\(\?<FIN>$1\)/; }
	      else { $ligne=~s/\(/\(\?<MOTIF>/; }

		# Substitution des variables utilisateur dans le texte
		foreach my $variable (keys %correspondance) { $ligne=~s/\_$variable/$correspondance{$variable}/g; }

		# Après substitution, la première parenthèse ouvrante
		# correspond au contexte gauche
		if ($ligne=~/\t\([^\?]/) { $ligne=~s/\t\(/\t\(\?<CONTEXTE>/; }

		# Stockage du contenu : balise et patron associé
		# (%tableau) et patron (@motifs, gestion de l'ordre)
		my ($balise,$patron)=split(/\t/,$ligne);
		$tableau{$patron}=$balise;
		push(@motifs,$patron);
		$types{$balise}++;
	    }
	}
    }
    close(E);

    return \%tableau;
}

sub traite() {
  warn "*** MEDINA (v3), 20/02/2014, configuration \"$schema\"\n";

    # Si l'option -r est utilisée, on traite les fichiers du
    # répertoire.
    if ($opt_r) {
	warn "9> traitement des documents\n";
	foreach my $fichier (@dossier) {
	    my $sortie=$fichier; $sortie=~s/$opt_e$/med/;
	    warn "   . $fichier -> $sortie\n";

	    #open(E,'<:utf8',$fichier);
	    open(E,$fichier);
	    open(S,">$sortie");
	    while (my $ligne_entree=<E>) {
		chomp $ligne_entree;
		my $ligne_sortie=application($ligne_entree);
		print S $ligne_sortie,"\n";
	    }
	    close(E);
	    close(S);
	}
    } 

    #  Sinon, on traite le flux courant.
    else {
	while (my $ligne_entree=<STDIN>) {
	    chomp $ligne_entree;
	    my $ligne_sortie=application($ligne_entree);
	    print $ligne_sortie,"\n";
	}
    }
}


sub application() {
    my $ligne_entree=$_[0];
    my $ligne_sortie=$ligne_entree;

    ###
    # Application du dictionnaire (formes qui ne doivent pas être annotées)
    ###

    # Chaque token identifié dans le dictionnaire et absent de
    # l'anti-dictionnaire (les termes utilisés dans la grammaire de
    # l'utilisateur) est encadré de tildes pour ne pas être annoté par
    # la suite (projection de lexiques ou application de règles).
    my $tokenisation=$ligne_entree;
    $tokenisation=~s/([[:punct:]])/ $1 /g;
    my @tokens=split(/\s+/,$tokenisation);
    foreach my $token (@tokens) {
	if (exists $lexique{"dico"} && defined $lexique{"dico"}->{$token}) {
	    if (!exists $anti_dico{$token}) {
		while ($tokenisation=~/(\W|^)$token(\W|$)/) {
		    $tokenisation=~s/(?<GAUCHE>\W|^)$token(?<DROITE>\W|$)/$+{GAUCHE}\~§§§§§\~$+{DROITE}/;
		    $ligne_entree=~s/(?<GAUCHE>\W|^)$token(?<DROITE>\W|$)/$+{GAUCHE}\~§§§§§\~$+{DROITE}/;
		    if ($opt_t && $ligne_entree=~/$opt_t/) { warn ":dico: $ligne_entree\n"; }
		}
	    }
	}
    }

    ###
    # Application de la grammaire de l'utilisateur
    ###

    foreach my $patron (@motifs) {

	# Récupération de la balise correspondant au patron
	my $balise="";
	foreach my $element (keys %grammaire) {
	    if (exists $grammaire{$element}->{$patron}) {
		$balise=$grammaire{$element}->{$patron};
		if ($opt_g) { $balise=$balise_defaut; }
	    }
	}

	while ($ligne_entree=~/(?<!\w)$patron(?!\w)/) {
	    # Mémorisation du contexte gauche non parenthésé
	    my $fragment=""; if ($patron=~/^(?<FRAGMENT>[^\(]+\s*)/) { $fragment=$+{FRAGMENT}; }
	    my $space=""; if ($+{CONTEXTE} ne "") { $space=" "; }

	    # Application du patron
	    #$ligne_entree=~s/$patron/$fragment$+{CONTEXTE}$space<$balise>§§§§§<\/$balise>$+{FIN}/g;
	    #$ligne_sortie=~s/$patron/$fragment$+{CONTEXTE}$space<$balise>$+{MOTIF}<\/$balise>$+{FIN}/g;
	    # $ligne_entree=~s/(?<HG>(\W|^))$patron(?<HD>(\W|$))/$fragment$+{CONTEXTE}$space$+{HG}<$balise>§§§§§<\/$balise>$+{HD}$+{FIN}/g;
	    # $ligne_sortie=~s/(?<HG>(\W|^))$patron(?<HD>(\W|$))/$fragment$+{CONTEXTE}$space$+{HG}<$balise>$+{MOTIF}<\/$balise>$+{HD}$+{FIN}/g;
	    $ligne_entree=~s/(?<HG>(\W|^))$patron(?<HD>(\W|$))/$+{HG}$fragment$+{CONTEXTE}$space$+{HG}<$balise>§§§§§<\/$balise>$+{FIN}$+{HD}/g;
	    $ligne_sortie=~s/(?<HG>(\W|^))$patron(?<HD>(\W|$))/$+{HG}$fragment$+{CONTEXTE}$space<$balise>$+{MOTIF}<\/$balise>$+{FIN}$+{HD}/g;
	    warn "-(grm) $+{CONTEXTE} $+{MOTIF}\t$balise\n" if ($opt_c);
	    $deja{$+{MOTIF}}++;
	    if ($opt_t && $ligne_sortie=~/$opt_t/) { warn ":grm: $ligne_entree\n:grm: $ligne_sortie\n"; }
	}

    }

    ###
    # Projection des lexiques
    ###

    my $tokenisation=$ligne_entree;
    $tokenisation=~s/((?!>)[[:punct:]]) / $1 /g;
    $tokenisation=~s/ (?!<)([[:punct:]])/ $1 /g;
    my @tokens=split(/\s+/,$tokenisation);
    foreach my $token (@tokens) {
	my $token_rx=quotemeta($token);
	
	foreach my $type (sort keys %lexique) {
	    my $balise=$balises{$type};
	    if ($opt_g) { $balise=$balise_defaut; }
	    if (exists $lexique{$type} && defined $lexique{$type}->{$token} && $type ne "dico") {
		# Recherche du token à l'identique
		while ($tokenisation=~/(\W|^)$token(\W|$)/) {
		    $tokenisation=~s/(?<GAUCHE>\W|^)$token_rx(?<DROITE>\W|$)/$+{GAUCHE}§§§§§$+{DROITE}/;
		    $ligne_entree=~s/(?<GAUCHE>\W|^)$token_rx(?<DROITE>\W|$)/$+{GAUCHE}<$balise>§§§§§<\/$balise>$+{DROITE}/;
		    $ligne_sortie=~s/(?<GAUCHE>\W|^)(?<MOTIF>$token_rx)(?<DROITE>\W|$)/$+{GAUCHE}<$balise>$+{MOTIF}<\/$balise>$+{DROITE}/;
		    warn "-(lxq $type) $+{MOTIF}\t$balise\n" if ($opt_c);
		    $deja{$+{MOTIF}}++;
		    if ($opt_t && $ligne_sortie=~/$opt_t/) { warn ":lxq $type: $ligne_entree\n:lxq $type: $ligne_sortie\n"; }
		}
		
		# Nettoyage pour : Saint(e) + balise précédemment utilisée (prénom, patient)
		if ($ligne_sortie=~/Sainte? <$balise> ([^<]+) <\/$balise>/) {
		    my $faux_prenom=$1;
		    $tokenisation=~s/(?<GAUCHE>Sainte?)§§§§§/$+{GAUCHE} $faux_prenom/;
		    $ligne_entree=~s/(?<GAUCHE>Sainte?)§§§§§/$+{GAUCHE} $faux_prenom/;
		    $ligne_sortie=~s/(?<GAUCHE>Sainte?)<$balise>(?<MOTIF>[^<]+)<\/$balise>/$+{GAUCHE} $+{MOTIF}/;
		}
	    }
	}

	# Application du dictionnaire si option -d ou -g : annotation
	# de tout ce qui est hors dictionnaire.
	if ($opt_d || $opt_g) {
	    if (exists $lexique{"dico"} && !defined $lexique{"dico"}->{$token}) {
		if ($token!~/[[:punct:]]/ && $token!~/^<[^>]+>$/ && $token!~/\d/ && length($token)>3 && $token!~/\§\§\§\§\§/) {
		    $tokenisation=~s/(?<GAUCHE>\W|^)$token_rx(?<DROITE>\W|$)/$+{GAUCHE}§§§§§$+{DROITE}/;
		    $ligne_entree=~s/(?<GAUCHE>\W|^)$token_rx(?<DROITE>\W|$)/$+{GAUCHE}§§§§§$+{DROITE}/;
		    $ligne_sortie=~s/(?<GAUCHE>\W|^)(?<MOTIF>$token_rx)(?<DROITE>\W|$)/$+{GAUCHE}<$balise_defaut>$+{MOTIF}<\/$balise_defaut>$+{DROITE}/;
		    warn "-(hors) $+{MOTIF}\n" if ($opt_c);
		    if ($opt_t && $ligne_sortie=~/$opt_t/) { warn ":hors: $ligne_entree\n:hors: $ligne_sortie\n"; }
		}
	    }
	}
	
    }

    ####
    # 19/02/2014 : projection du contenu des lexiques sur l'ensemble
    # de la ligne et non plus token par token, permet de gérer les
    # expressions composées de plusieurs mots. Temps de traitement
    # beaucoup plus long ; processus désactivé si option -x utilisée.
    if (!$opt_x) {
	foreach my $type (sort keys %lexique) {
	    my $balise=$balises{$type};

	    if ($opt_g) { $balise=$balise_defaut; }
	    if ($type ne "dico") {
		foreach my $token (keys $lexique{$type}) {
		    while ($ligne_entree=~/(\W|^)$token(\W|$)/) {
			$ligne_entree=~s/(?<GAUCHE>\W|^)$token(?<DROITE>\W|$)/$+{GAUCHE}<$balise>§§§§§<\/$balise>$+{DROITE}/;
			$ligne_sortie=~s/(?<GAUCHE>\W|^)(?<MOTIF>$token)(?<DROITE>\W|$)/$+{GAUCHE}<$balise>$+{MOTIF}<\/$balise>$+{DROITE}/;
			warn "-(lxq $type) $+{MOTIF}\t$balise\n" if ($opt_c);
			$deja{$+{MOTIF}}++;
			if ($opt_t && $ligne_sortie=~/$opt_t/) { warn ":lxq $type: $ligne_entree\n:lxq $type: $ligne_sortie\n"; }
		    }
		}
	    }
	}
    }
    ###


    # Les séquences "<Xabb>annotation</Xabb>."  qui dénotent une
    # abréviation se terminant par un point, avec point à l'extérieur,
    # deviennent "<X>annotation.</X>" avec point à l'intérieur de la
    # portion annotée.  $ligne_sortie=~s/\\././g; # Transforme "\&" en
    # "."
    while ($ligne_sortie=~/<\/(?<BALISE>\w*?)abb>\./i) {
	my $balise=$+{BALISE}; my $anc=$balise."abb";
	$ligne_sortie=~s/<\/$anc>\./\.<\/$balise>/gi; # Fermante
	$ligne_sortie=~s/<$anc>/<$balise>/gi;         # Ouvrante
    }

    # Suppression des séquences de balisage individuel (<a> mot </a>
    # <a> mot </a> devient <a> mot mot </a>), suppression des espaces
    # multiples.
    foreach my $bal (sort keys %types) { $ligne_sortie=~s:</$bal>(?<SEP>\s+)<$bal>:$+{SEP}:g; }
    #if ($ligne_sortie=~m:</(?<FERMANT>[^>]+)>(?<SEP>\s*)<(?<OUVRANT>[^>]+)>:) { if ($+{FERMANT} eq $+{OUVRANT}) { $ligne_sortie=~s:</$+{FERMANT}>$+{SEP}<$+{OUVRANT}>:$+{SEP}:g; } }  # Si seule l'option -d est utilisée, les éléments de portions consécutives "hors" sont bien rassemblés, mais les espaces qui séparent chaque token disparaissent.
    $ligne_sortie=~s/<patient>IV<\/patient>/IV/g;
    $ligne_sortie=~s/<\/patient>(?<MOTIF>\s?[A-Z]\p{L}+\s?)<patient>/$+{MOTIF}/g;

    # Suppression des annotations multiples de même type
    $ligne_sortie=~s/(?<BAL1>\<[^\>]+\>)(?<PRE>[^<]*)(?<BAL2>\<[^\>]+\>)(?<INSIDE>[^<]*)(?<BAL3>\<\/[^\>]+\>)(?<POST>[^<]*)(?<BAL4>\<\/[^\>]+\>)/$+{BAL1}$+{PRE}$+{INSIDE}$+{POST}$+{BAL4}/g;
    $ligne_sortie=~s/(?<BAL1>\<[^\>]+\>)(?<PRE>[^<]*)(?<BAL2>\<[^\>]+\>)(?<INSIDE>[^<]*)(?<BAL3>\<\/[^\>]+\>)(?<POST>[^<]*)(?<BAL4>\<\/[^\>]+\>)/$+{BAL1}$+{PRE}$+{INSIDE}$+{POST}$+{BAL4}/g;

    # Propagation des annotations à la place de la balise "hors" : X + hors -> X
    if ($opt_p) {
	# Florence</patient> <hors>BLABLA</hors> -> Florence BLABLA</patient>
	while ($ligne_sortie=~m:(?<BAL1></[^>]+>)\s+<$balise_defaut>(?<CONTENU>[^<]+)</$balise_defaut>:) {
	    $ligne_sortie=~s:</(?<BAL1>[^\>]+)>(?<SEP>\s+)<$balise_defaut>(?<CONTENU>[^<]+)</$balise_defaut>:$+{SEP}$+{CONTENU}</$+{BAL1}>:g;
	}
	# <hors>BLABLA</hors> <patient>Florence -> <patient>BLABLA Florence
	while ($ligne_sortie=~m:<$balise_defaut>(?<CONTENU>[^<]+)</$balise_defaut>\s+(?<BAL1><[^>]+>):) {
	    $ligne_sortie=~s:<$balise_defaut>(?<CONTENU>[^<]+)</$balise_defaut>(?<SEP>\s+)<(?<BAL1>[^\>]+)>:<$+{BAL1}>$+{CONTENU}$+{SEP}:g;
	}
    }

    # Affichage de la ligne annotée dans le document de sortie
    #print S $ligne_sortie,"\n";
    return $ligne_sortie;
}


###
# Documentation PERL
###

# Nommage des variables
# if (?<name>pattern) { print $+{name}; }

# Tests sur les frontières de patrons
# - positive look ahead: (?=pattern)
# - negative look ahead: (?!pattern)
# - positive look behind: (?<=pattern)
# - negative look behind: (?<!pattern)


# Les éléments de la grammaire sous forme d'abréviations se terminant
# par un point (p.o., t.i.d., etc.) posent problème pour la boucle
# "tant_qu'il est possible d'appliquer le patron" (un patron = la
# disjonction des motifs cherchés). Le problème concerne la frontière
# droite (look-ahead) et le caractère pris dans cette frontière : dans
# le cas des abréviations, le point est partie prenante du motif, dans
# d'autres cas, le point est une limite. Difficulté de distinguer les
# deux. Problème résolu en déclarant, dans la grammaire, des balises
# qui se terminent par "abb" (modeabb, freqabb) ; Medina interprète
# ces balises spéciales par le fait que le patron se termine par un
# point d'abbréviation et non un point de fin de ligne, et qu'il ne
# s'agit pas non plus du point des expressions régulières (n'importe
# quel caractère).
