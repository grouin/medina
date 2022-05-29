#!/usr/bin/perl

# Produit un tabulaire au format voulu à partir d'annotations
# embarquées. Ne gère pas les annotations imbriquées.

# Usage : perl zero_tabulaire.pl repertoire/ extension nomFichierTabulaire format [liste,tags,à,conserver]
# perl zero_tabulaire.pl corpus/ tag tab_train.zero BWEMO+
# perl zero_tabulaire.pl corpus/ tag tab_train.zero BWEMO+ Personne,Organisation

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

# Ubuntu 20.04 : Soundex.c: loadable library and perl binaries are mismatched (got handshake key 0xde00080, needed 0xcd00080)
# medina$ sudo perl -MCPAN -e 'recompile()'
# medina$ conda install -c conda-forge perl-text-soundex


use strict;
use utf8;
use Text::Soundex;

my @rep=<$ARGV[0]/*$ARGV[1]>;
my $sortie=$ARGV[2];
my $format=$ARGV[3];
my $listeTags=$ARGV[4]; $listeTags="(".$listeTags.")"; $listeTags=~s/\,/\|/g;
my %frequenceToken=();
my %frequenceConsonnes=();
my %frequenceVoyelles=();
my %frequenceTrigrammes=();
my $total=0;
my $totalCar=0;
my $fichierPOS="scripts/data/forme-lemme-pos.tab";
my $fichierTri="scripts/data/liste_ngrammes.txt";
my %tabPOS=();
my $typeOffset="l"; # g(lobal) pour MAPA vs. l(ocal) pour le reste

warn "Applying $format annotation schema\n";


###
# Récupération de données statistiques

&recuperePOS();
&recupereTri();
&frequencesToken();


# Traitement du corpus
my @tabulaire=();
my @labels=();
foreach my $fichier (@rep) {
  push(@tabulaire,"$fichier\tnul\tnul\tnul\tnul\tnul\tnul\tnul\tnul\tnul\tnul\tnul\tnul\t");
  push(@labels,"O");
  my $numLigne=0;
  my $indexGlobal=0;
  my $indexGlobPrec=0;
  my $texte="";
  
  open(E,'<:utf8',$fichier);
  while (my $ligne=<E>) {
    # 28-02-2022 prise en compte des attributs
    my $nw=0;
    while ($ligne=~/\<(\w+) [^\=\"\>]+\=\"([^\"]+)\"\>/) {
      my ($label,$attribut)=($1,$2);
      $ligne=~s/<$label [^\=\"\>]+\=\"$attribut\">([^\<]+)<\/$label>/<$label\_$attribut>$1<\/$label\_$attribut>/g;
      $nw++; if ($nw==10) { print "PB>\t$ligne"; exit; }
    }
    ###
    # Calcul des offsets : texte global stocké avant normalisation
    # mais sans les annotations embarquées dans le texte
    my $ligneOrig=$ligne; $ligneOrig=~s/<\/?[^>]+>//g;
    $texte.=$ligneOrig;
    ###
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
      if ($token=~/<([^>\/]+)>/) { $tag=$1; $token=~s/<$tag>//; }
      # Le tag reste le même tant qu'on ne rencontre pas de balise fermante
      if ($token=~/<\/([^>]+)>/) { $fin=$1; $token=~s/<\/$fin>//; }

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
      if ($token=~/^(Madame|madame|Mademoiselle|mademoiselle|Monsieur|monsieur|Mme|M\.|Mr\.?|Melle|Me|MR\.?|Pr\.?|PR\.?|Professeur|professeur|Dr\.?|DR\.?|Docteur|docteur|Cher|Chère|cher|chère|Nom|NOM|Prénom|PRENOM)$/) { $decl="pers"; }
      elsif ($token=~/^(janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre|lundi|mardi|mercredi|jeudi|vendredi|samedi|dimanche|monday|tuesday|wednesday|thursday|friday|saturday|sunday|january|february|march|april|may|june|july|august|september|october|november|december)$/i) { $decl="date"; }
      elsif ($token=~/^(CH|CHG|CHR|CHU|clinique|hôpital|hôpitaux|hospitalier|hospices|hôtel|institut|laboratoire|maternité|centre|fondation|groupe|groupement|unité|universitaire|adultes|enfants)$/i) { $decl="hosp"; }
      elsif ($token=~/^(à|au|aux|en|le)$/i) { $decl="dtprp"; }
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

      # Trigrammes de caractères (fréquence du trigramme le plus rare dans le token)
      my $tri=&trigrammes($token);

      # Printing
      my $index=index($ligne,$token,$indexPrecedent);
      $indexGlobal=index($texte,$token,$indexGlobPrec);
      my $label="O";
      if ($tag eq "O") { $label="O"; }
      if ($tag!~/$listeTags/) { $tag="O"; }
      if ($token ne "") {
	if ($typeOffset eq "l") { push(@tabulaire,"$numLigne\-$index\t$token\t$taille\t$interT\t$pos\t$decl\t$freq\t$rareConsonne\t$rareVoyelle\t$soundex\t$nombreSyllabes\t$schemaSyllabes\t$tri\t"); }
	else {
	  my $indexGlobFin=$indexGlobal+length($token);
	  push(@tabulaire,"$indexGlobal\-$indexGlobFin\t$token\t$taille\t$interT\t$pos\t$decl\t$freq\t$rareConsonne\t$rareVoyelle\t$soundex\t$nombreSyllabes\t$schemaSyllabes\t$tri\t");
	}
	push(@labels,$tag);
      }

      # Reinitializations
      if ($fin ne "") { $tag="O"; }
      $prec=$tag;
      $indexPrecedent=$index+length($token);
      $indexGlobPrec=$indexGlobal+length($token);

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
}

sub recupereTri() {
  # Récupération des fréquences des trigrammes de caractères
  open(E,$fichierTri) or die "Impossible d'ouvrir $fichierTri\n";
  while (my $ligne=<E>) {
    chomp $ligne;
    my @cols=split(/\t/,$ligne);
    $frequenceTrigrammes{$cols[0]}=$cols[1];
  }
  close(E);
}

sub frequencesToken() {
  # Calcul de la fréquence d'utilisation de chaque token du corpus
  # traité
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
	$frequenceVoyelles{$car}++ if ($car=~/[aeiouyàâäéèêëîìïôòöûùüỳÿœ]/i);
	$totalCar++;
      }
    }
  }
}

sub normalisation() {
  my $contenu=shift;
  # Protection des URLs et e-mails pour éviter d'ajouter des espaces
  $contenu=~s/((ftp|http)[^\s\(\)\[\]]+)/\[URL\]$1\[\/URL\]/g;
  $contenu=~s/([^\s\(\)\[\]]+)\@([^\s\(\)\[\]]+)/\[URL\]$1\@$2\[\/URL\]/g;
  # Ajout d'espaces autour des ponctuations, sauf celles utilisées
  # dans les décimales ou dans les dates : - / .
  $contenu=~s/([\.\-,\(\)\|\'\’\@\#])/ $1 /g;
  $contenu=~s/([^<])\//$1 \/ /g;        # Slash, sauf dans balise fermante
  $contenu=~s/\[ \/ URL\]/\[\/URL\]/g;  # y compris balises de protection
  $contenu=~s/(\d) \. (\d)/$1\.$2/g;
  $contenu=~s/(\d) \, (\d)/$1\,$2/g;
  $contenu=~s/(\d) \/ (\d)/$1\/$2/g; # Pas d'espace dans les dates
  # Balises dont le nom est composé d'un point (Quaero) ou d'un tiret (INaLCO)
  $contenu=~s/<([^>]*?) ([\-\.]) ([^>]*?) ([\-\.]) ([^>]*?)>/<$1$2$3$4$5>/g; # <loc.adm.town>
  $contenu=~s/<([^>]*?) ([\-\.]) ([^>]*?)>/<$1$2$3>/g;                    # <pers.ind>
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
  # ajout d'une espace après chaque voyelle graphémique ; suppression
  # des espaces avant les consonnes finales (rattachement des
  # consonnes finales à la syllabe précédente), de toutes les espaces
  # finales (pour éviter les erreurs de décomptes), et des espaces
  # avant consonnes finales terminées par un schwa, éventuellement au
  # pluriel (e.g., Charles) ; maintien du hiatus
  $entree=~s/([aeiouyâàêéèëîïôöûùüœ]+)/$1 /gi;
  $entree=~s/ ([bcdfghjklmnpqrstvwxz]+)$/$1/gi;
  $entree=~s/ $//;
  $entree=~s/ ([bcdfghjklmnpqrstvwxz]+)(e|es)$/$1$2/gi;
  $entree=~s/(é|o|u)(o|a|ï|ë)/$1 $2/g;
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

sub trigrammes() {
  # Découpe le token pris en entrée en trigrammes de caractères et
  # retourne la fréquence d'utilisation du trigramme le plus rare dans
  # le token
  my $entree=lc(shift); my $ft=10000; my $nbTri=0;
  for (my $i=0;$i<length($entree)-2;$i++) {
    my $ngr=substr($entree,$i,3);
    if ($ngr=~/^\p{L}{3}$/) {
      # La fréquence du trigramme le plus rare dans le mot est conservée
      #if (exists $frequenceTrigrammes{$ngr} && $frequenceTrigrammes{$ngr}<$ft) { $ft=$frequenceTrigrammes{$ngr}; }
      # Moyenne des fréquences de tous les trigrammes
      if (exists $frequenceTrigrammes{$ngr}) { $ft+=$frequenceTrigrammes{$ngr}; $nbTri++; }
    }
  }
  if ($ft==10000) { $ft="nul"; }
  # Moyenne
  else { $ft-=10000; $ft=sprintf("%.3f",$ft/$nbTri) if ($nbTri>0); }
  return $ft;
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
  if (($avant eq "O" || $avant eq "" || $avant ne $courant) && $courant ne "O" && $courant ne "" && ($apres eq "O" || $apres eq "" || $apres ne $courant)) { $t="W-$courant"; }
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
  if (($avant eq "O" || $avant eq "" || $avant ne $courant) && $courant ne "O" && $courant ne "" && ($apres eq "O" || $apres eq "")) { $t="I-$courant"; }
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
  if ($l=~/\tVer\:/ || $l=~/\tNom\:[^P]/) { $t=~s/^[A-Z]-/H-/; }
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
