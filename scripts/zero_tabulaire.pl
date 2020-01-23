#!/usr/bin/perl

# Produit un tabulaire au format voulu à partir d'annotations
# embarquées. Ne gère pas les annotations imbriquées.

# Usage : perl zero_tabulaire.pl repertoire/ extension nomFichierTabulaire format

# Formats : IO BIO BIO2 (le plus courant) BIO2H BWEMO BWEMO+
# - IO : in/out
# - BIO : begin/in/out, un élément isolé reçoit le préfixe I
# - BIO2 : begin/in/out, un élément isolé reçoit le préfixe B
# - BIO2H : begin/in/out, la tête de syntagme reçoit le préfixe H
# - BWEMO : begin/word/end/middle/out, un élément isolé reçoit le
#   préfixe W, le dernier élément annoté reçoit le préfixe E
# - BWEMO+ : idem, les fins de ligne reçoivent l'étiquette O-EOS, et
#   les O qui précèdent une portion annotée reçoivent l'étiquette de
#   la portion qui suit avec le préfixe O

# Auteur : Cyril Grouin, octobre 2019.

use strict;
use utf8;
use Text::Soundex;

my @rep=<$ARGV[0]/*$ARGV[1]>;
my $sortie=$ARGV[2];
my $format=$ARGV[3];
my %frequenceToken=();
my %frequenceConsonnes=();
my %frequenceVoyelles=();
my $total=0;
my $totalCar=0;
my $fichierPOS="scripts/data/forme-lemme-pos.tab";
my %tabPOS=();

warn "Applying $format annotation schema\n";

# Récupération des POS
open(E,$fichierPOS);
while (my $ligne=<E>) {
    chomp $ligne;
    my @cols=split(/\t/,$ligne);
    $tabPOS{$cols[0]}=$cols[2];
    # Ajout d'une version désaccentuée
    my $desaccent=$cols[0]; $desaccent=~s/[éèê]/e/g;
    if ($desaccent ne $cols[0]) { $tabPOS{$desaccent}=$cols[2]; }
}
close(E);

# Premier parcours du corpus : calcul de la fréquence d'utilisation de
# chaque token du corpus traité
foreach my $fichier (@rep) {
  open(E,'<:utf8',$fichier);
  while (my $ligne=<E>) {
    my $norm=&normalisation($ligne);
    $norm=~s/<[^>]+>//g;

    # Tokénisation
    my @tokens=split(/ /,$norm);
    foreach my $token (@tokens) { $frequenceToken{$token}++; $total++; }
    # Tokénisation caractères
    my @cars=split(//,$norm);
    foreach my $car (@cars) {
	$car=lc($car);
	$frequenceConsonnes{$car}++ if ($car=~/[bcdfghjklmnpqrstvwxzç]/i);
	$frequenceVoyelles{$car}++ if ($car=~/[aeiouyàâäéèêëîìïôòöûùüỳÿ]/i);
	$totalCar++;
    }
  }
}



# Deuxième parcours du corpus : traitement du corpus
my @tabulaire=();
my @labels=();
foreach my $fichier (@rep) {
  push(@tabulaire,"$fichier\tnul\tnul\tnul\tnul\tnul\tnul\tnul\tnul\tnul\tnul\tnul\t");
  push(@labels,"O");
  my $numLigne=0;
  
  open(E,'<:utf8',$fichier);
  while (my $ligne=<E>) {
    my $norm=&normalisation($ligne);
    $ligne=~s/<[^>]+>//g;
    my $indexPrecedent=0;

    # Tokenization
    my @tokens=split(/ /,$norm);

    # Réinitializations
    my $tag="O";
    my $prec="O";
    my $taille=0;
    my $interT=0;
    my $pos="";
    my $decl="nul";

    foreach my $token (@tokens) {
      my $fin="";
      my $freq="rare";
      my $rareConsonne="nul";
      my $rareVoyelle="nul";

      # Opening tag
      if ($token=~/<([^>\/]+)>/) {
	$tag=$1; $token=~s/<$tag>//;
      }
      # Le tag reste le même tant qu'on ne rencontre pas de balise fermante
      if ($token=~/<\/([^>]+)>/) {
	$fin=$1; $token=~s/<\/$fin>//;
      }

      # Taille absolue (nombre exact de caractères) et sur une échelle à trois valeurs
      $taille=length($token);
      if ($taille<4) { $interT="p"; } elsif ($taille<8) { $interT="m"; } else { $interT="g"; }

      # Etiquetage en parties du discours (d'après les listes du CNAM avec amélioration sur les tokens inconnu commençant par une majuscule)
      my $tokmin=lc($token);
      if (exists $tabPOS{$tokmin}) { $pos=$tabPOS{$tokmin}; }
      elsif (length($token)>=4 && $token=~/^[A-Z]\p{L}+$/) { $pos="Nom:Propre"; }
      elsif ($token=~/^d\'$/i) { $pos="Pre"; }
      elsif ($token=~/^l\'$/i) { $pos="Det:Mas+SG"; }
      elsif ($token=~/^[[:digit:]]+$/) { $pos="Num"; }
      elsif ($token=~/^[[:punct:]]+$/) { $pos="Pct"; }
      else { $pos="nul"; }

      # Trigger words
      if ($token=~/^(Madame|madame|Monsieur|monsieur|Mme|M\.|Mr|Melle|Me|MR|Pr|PR|Professeur|professeur|Dr|DR|Docteur|docteur|Cher|Chère|cher|chère|Nom|NOM|Prénom|PRENOM)$/) { $decl="pers"; }
      elsif ($token=~/^(janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre|lundi|mardi|mercredi|jeudi|vendredi|samedi|dimanche|monday|tuesday|wednesday|thursday|friday|saturday|sunday|january|february|march|april|may|june|july|august|september|october|november|december)$/i) { $decl="date"; }
      elsif ($token=~/^(CH|CHR|CHU|clinique|hôpital|hôpitaux|hospitalier|hospices|hôtel|institut|laboratoire|maternité|centre|fondation|groupe|groupement|universitaire|adultes|enfants)$/i) { $decl="hosp"; }
      else { $decl="nul"; }

      # Fréquence d'utilisation du token dans le corpus (binaire)
      if ($frequenceToken{$token}<=($total/2000) && $token=~/^\p{L}+$/i) { $freq="rare"; } else { $freq="commun"; }
      # Fréquence d'utilisation des caractères du token dans le corpus (soit il y a des consonnes ou des voyelles rares dans le token, soit il n'y en a pas)
      my @cars=split(//,$token);
      foreach my $car (@cars) {
	  $car=lc($car);
	  if ($car=~/[bcdfghjklmnpqrstvwxzç]/) { if ($frequenceConsonnes{$car}<=($totalCar/250)) { $rareConsonne="cons"; } }
	  if ($car=~/[aeiouyàâäéèêëîìïôòöûùüỳÿ]/) { if ($frequenceVoyelles{$car}<=($totalCar/250)) { $rareVoyelle="voy"; } }
      }

      # Code Soundex
      my $soundex="NUL";
      $soundex=soundex($token) if ($token=~/^\p{L}+$/);
      if ($soundex eq "") { $soundex="NUL"; }

      # Syllabation
      my ($nombreSyllabes,$schemaSyllabes)=(0,"nul");
      if ($token=~/^\p{L}+$/) { ($nombreSyllabes,$schemaSyllabes)=&syllabes($token); }

      # Printing
      my $index=index($ligne,$token,$indexPrecedent);
      my $label="O";
      if ($tag eq "O") { $label="O"; }
      if ($token ne "") {
	  push(@tabulaire,"$numLigne\-$index\t$token\t$taille\t$interT\t$pos\t$decl\t$freq\t$rareConsonne\t$rareVoyelle\t$soundex\t$nombreSyllabes\t$schemaSyllabes\t");
	  push(@labels,$tag);
      }

      # Reinitializations
      if ($fin ne "") { $tag="O"; }
      $prec=$tag;
      $indexPrecedent=$index+length($token);

    }
    $numLigne++;

    # New line
    push(@tabulaire,"");
    push(@labels,"");
  }
  close(E);
}


# Production du tabulaire final
open(S,'>:utf8',"$sortie");
my $i=0;
foreach my $ligne (@tabulaire) {
    my $tag="";
    
    # Appel des routines en fonction du format voulu
    if ($format eq "BWEMO") { $tag=&bwemo($labels[$i-1],$labels[$i],$labels[$i+1]); }
    elsif ($format eq "BWEMO+") { $tag=&bwemoPlus($labels[$i-1],$labels[$i],$labels[$i+1]); }    
    elsif ($format eq "IO") { $tag=&io($labels[$i-1],$labels[$i],$labels[$i+1]); }
    elsif ($format eq "BIO") { $tag=&bio($labels[$i-1],$labels[$i],$labels[$i+1]); }
    elsif ($format eq "BIO2H") { $tag=&bio2h($labels[$i-1],$labels[$i],$labels[$i+1],$ligne); }
    else { $tag=&bio2($labels[$i-1],$labels[$i],$labels[$i+1]); }

    # Pas d'étiquette en l'absence de token
    if ($labels[$i] eq "") { $tag=""; }

    #if ($ligne eq "") { $ligne="_"; }
    print S "$ligne$tag\n";
    $i++;
}
close(S);



###
# Routines

sub normalisation() {
  my $contenu=shift;
  # Protection des URLs et e-mails pour éviter d'ajouter des espaces
  $contenu=~s/((ftp|http)[^\s\(\)\[\]]+)/\[URL\]$1\[\/URL\]/g;
  $contenu=~s/([^\s\(\)\[\]]+)\@([^\s\(\)\[\]]+)/\[URL\]$1\@$2\[\/URL\]/g;
  # Ajout d'espaces autour des ponctuations, sauf celles utilisées
  # dans les décimales ou dans les dates : - / .
  $contenu=~s/([\.\-,\(\)\|\'\’\@\#])/ $1 /g;
  $contenu=~s/(\d) \. (\d)/$1\.$2/g;
  $contenu=~s/(\d) \, (\d)/$1\,$2/g;
  # Rétablissement des URLs et e-mails par la suppression des espaces
  # contenues dans ce qui a été balisé URL
  my $url="";
  while ($contenu=~/\[URL\](.*?)\[\/URL\]/) { $url=$1; $url=~s/\s+//g; $contenu=~s/\[URL\].*?\[\/URL\]/$url/; $contenu=~s/\.( |$)/ \.$1/; }
  while ($contenu=~/\[URL\]([^\s\(\)\[\]]+?\@[^\s\(\)\[\]]+?)\[\/URL\]/) { $url=$1; $url=~s/\s+//g; $contenu=~s/\[URL\].*?\[\/URL\]/$url/; $contenu=~s/\.( |$)/ \.$1/; }
  # Post-traitements divers
  $contenu=~s/aujourd \' hui/aujourd\'hui/g; $contenu=~s/aujourd \’ hui/aujourd\’hui/g;
  $contenu=~s/(.) ([\'\’]) (.)/$1$2 $3/g;
  $contenu=~s/http([^\s]+) \. ([^\s]+)/http$1\.$2/;
  # Réduction des espaces multiples
  $contenu=~s/\s+/ /g;
  $contenu=~s/^\s+//g;
  # Si des balises encadrent le texte, il faut les supprimer pour
  # éviter qu'elles ne soient utilisées comme catégorie à prédire
  $contenu=~s/<\/?texte>//g;

  return $contenu;
}

sub syllabes() {
  # Nombre de syllabes et schémas de syllabation. Il s'agit d'une
  # approximation dans la mesure où l'objet pris en entrée est du
  # texte et non une transcription de la parole
  my $entree=shift;
  $entree=~s/([aeiouyâàêéèëîïôöûùü]+)/$1 /gi;           # ajout espace
  $entree=~s/ ([bcdfghjklmnpqrstvwxz]+)$/$1/gi;         # consonnes finales : dans, brest
  $entree=~s/ $//;                                      # suppression espace finale
  $entree=~s/ ([bcdfghjklmnpqrstvwxz]+)(e|es)$/$1$2/gi; # consonnes finales : Charles
  $entree=~s/(é|o|u)(o|a|ï|ë)/$1 $2/g;                  # maintien du hiatus
  my $nombreSyllabes=split(/ /,$entree);
  # Forme syllabique
  $entree=~s/(.{2,})que$/$1k/;                          # -que
  $entree=~s/(.{2,})es?$/$1/;                           # schwa
  $entree=~s/(.{2,})e[rt]s?$/$1é/;                      # premier, décret
  $entree=~s/(.{2,})[sx]$/$1/;                          # pluriel
  $entree=~s/ti([aeo])n$/s§$1~/g;                       # si-tion : si-sjo~
  $entree=~s/i([aeo])/§$1/g;                            # officiel : sjel
  $entree=~s/ph/f/g;                                    # phlébite
  $entree=~s/ [mn]([bcdfghjklpqrstvwxz])/~ $1/gi;       # co-mpo : co~-po
  $entree=~s/nt$/~/g;                                   # président : préside~
  $entree=~s/ c([bcdfgjkmnpqstvwxz])/c $1/gi;           # o-ctobr : oc-tobr (dé-cret)
  $entree=~s/ r([bcdfghjklmnpqstvwxz])/r $1/gi;         # po-rtant : por-tant
  $entree=~s/ s([bcdfghklmnpqrstvwxz])/s $1/gi;         # di-sponibl : dis-ponibl
  # suppression des lettres dupliquées
  my $old="#"; my $new=""; my @cars=split(//,$entree);
  foreach my $c (@cars) { if ($old ne $c) { $new.=$c; } $old=$c; }
  $entree=$new;
  $entree=~s/([bcçdfghjklmnpqrstvwxz])/c/gi;            # consonnes
  $entree=~s/([aeiouyâàêéèëîïôöûùü\~]+)/v/gi;           # voyelles (en dernier)
  $entree=~s/^\s+//g; $entree=~s/\s+$//g; $entree=~s/ /_/g;
  #$entree=&decoupe($entree);
  if ($entree eq "") { $entree="nul"; }
  return ($nombreSyllabes,$entree);
}

sub decoupe() {
    # Prend en entrée la représentation syllabique d'un token (sous la
    # forme v_cv_cv) et renvoie en sortie les différentes formes
    # syllabiques triées
    my $forme=shift; my $forme2="";
    my @syll=split(/\_/,$forme); my %tri=();
    foreach my $s (@syll) { $tri{$s}++; }
    foreach my $s (sort keys %tri) { $forme2.="$s\_"; }
    chop $forme2;
    # Renvoie uniquement l'existence de certaines formes syllabiques (cv cvc cvcc ccv ccvc)
    # if (exists $tri{"cv"}) { $forme2="1"; } else { $forme2="0"; }
    # if (exists $tri{"cvc"}) { $forme2.="1"; } else { $forme2.="0"; }
    # if (exists $tri{"cvcc"}) { $forme2.="1"; } else { $forme2.="0"; }
    # if (exists $tri{"ccv"}) { $forme2.="1"; } else { $forme2.="0"; }
    # if (exists $tri{"ccvc"}) { $forme2.="1"; } else { $forme2.="0"; }
    return $forme2;
}

sub bwemo() {
    my ($avant,$courant,$apres)=@_;
    my $t="O";
    # - W-annotation isolée
    if (($avant eq "O" || $avant eq "" || $avant ne $courant) && $courant ne "O" && $courant ne "" && ($apres eq "O" || $apres eq "")) { $t="W-$courant"; }
    # - B-début d'annotation
    elsif (($avant eq "O" || $avant eq "" || $avant ne $courant) && $courant ne "O" && $apres ne "O" && $courant ne "" && $apres ne "") { $t="B-$courant"; }
    # - M-milieu d'annotation
    elsif ($avant eq $courant && $courant ne "O" && $courant ne "" && $apres ne "O" && $apres ne "") { $t="M-$courant"; }
    # - E-fin d'annotation
    elsif ($avant eq $courant && $courant ne "O" && $courant ne "" && ($apres eq "O" || $apres eq "") && $apres ne $courant) { $t="E-$courant"; }
    # - O le cas échéant
    else { $t="O"; }
    return $t;
}

sub bwemoPlus() {
    my ($avant,$courant,$apres)=@_;
    my $t="O";
    # - W-annotation isolée
    if (($avant eq "O" || $avant eq "" || $avant ne $courant) && $courant ne "O" && $courant ne "" && ($apres eq "O" || $apres eq "")) { $t="W-$courant"; }
    # - B-début d'annotation
    elsif (($avant eq "O" || $avant eq "" || $avant ne $courant) && $courant ne "O" && $apres ne "O" && $courant ne "" && $apres ne "") { $t="B-$courant"; }
    # - M-milieu d'annotation
    elsif ($avant eq $courant && $courant ne "O" && $courant ne "" && $apres ne "O" && $apres ne "") { $t="M-$courant"; }
    # - E-fin d'annotation
    elsif ($avant eq $courant && $courant ne "O" && $courant ne "" && ($apres eq "O" || $apres eq "") && $apres ne $courant) { $t="E-$courant"; }
    # O-plus
    elsif ($courant eq "O" && $apres ne "O") {
	if ($apres ne "") { $t="O-$apres"; }
	else { $t="O-EOS"; }
    }
    # - O le cas échéant
    else { $t="O"; }
    return $t;
}

sub io() {
    my ($avant,$courant,$apres)=@_;
    my $t="O";
    # - I-début/milieu/fin d'annotation
    if (($avant eq "O" || $avant eq "" || $avant ne $courant) && $courant ne "O" && $courant ne "") { $t="I-$courant"; }
    elsif ($avant eq $courant && $courant ne "O" && $courant ne "" && $apres ne "O" && $apres ne "") { $t="I-$courant"; }
    elsif ($avant eq $courant && $courant ne "O" && $courant ne "" && ($apres eq "O" || $apres eq "")) { $t="I-$courant"; }
    # - O le cas échéant
    else { $t="O"; }
    return $t;
}

sub bio() {
    my ($avant,$courant,$apres)=@_;
    my $t="O";
    # - I-annotation isolée
    if (($avant eq "O" || $avant eq "" || $avant ne $courant) && $courant ne "O" && $courant ne "") { $t="I-$courant"; }
    # - B-début d'annotation
    elsif (($avant eq "O" || $avant eq "" || $avant ne $courant) && $courant ne "O" && $apres ne "O" && $courant ne "" && $apres ne "") { $t="B-$courant"; }
    # - I-milieu/fin d'annotation
    elsif ($avant eq $courant && $courant ne "O" && $courant ne "" && $apres ne "O" && $apres ne "") { $t="I-$courant"; }
    elsif ($avant eq $courant && $courant ne "O" && $courant ne "" && ($apres eq "O" || $apres eq "") && $apres ne $courant) { $t="I-$courant"; }
    # - O le cas échéant
    else { $t="O"; }
    return $t;
}

sub bio2h() {
    my ($avant,$courant,$apres,$l)=@_;
    my $t="O";
    # - I-annotation isolée
    if (($avant eq "O" || $avant eq "" || $avant ne $courant) && $courant ne "O" && $courant ne "" && ($apres eq "O" || $apres eq "")) { $t="I-$courant"; }
    # - B-début d'annotation
    elsif (($avant eq "O" || $avant eq "" || $avant ne $courant) && $courant ne "O" && $apres ne "O" && $courant ne "" && $apres ne "") { $t="B-$courant"; }
    # - I-milieu/fin d'annotation
    elsif ($avant eq $courant && $courant ne "O" && $courant ne "" && $apres ne "O" && $apres ne "") { $t="I-$courant"; }
    elsif ($avant eq $courant && $courant ne "O" && $courant ne "" && ($apres eq "O" || $apres eq "") && $apres ne $courant) { $t="I-$courant"; }
    # - O le cas échéant
    else { $t="O"; }
    # Tête de syntagme : essai sur les verbes et les noms (dans les portions annotées), ne sont pas des têtes de syntagme
    if ($l=~/\tVer\:/ || $l=~/\tNom\:/) { $t=~s/^[A-Z]-/H-/; }
    return $t;
}
    
sub bio2() {
    my ($avant,$courant,$apres)=@_;
    my $t="O";
    # - B-début d'annotation ou annotation isolée
    if (($avant eq "O" || $avant eq "" || $avant ne $courant) && $courant ne "O" && $courant ne "" && ($apres eq "O" || $apres eq "")) { $t="B-$courant"; }
    elsif (($avant eq "O" || $avant eq "" || $avant ne $courant) && $courant ne "O" && $apres ne "O" && $courant ne "" && $apres ne "") { $t="B-$courant"; }
    # - I-milieu/fin d'annotation
    elsif ($avant eq $courant && $courant ne "O" && $courant ne "" && $apres ne "O" && $apres ne "") { $t="I-$courant"; }
    elsif ($avant eq $courant && $courant ne "O" && $courant ne "" && ($apres eq "O" || $apres eq "")) { $t="I-$courant"; }
    # - O le cas échéant
    else { $t="O"; }
    return $t;
}
