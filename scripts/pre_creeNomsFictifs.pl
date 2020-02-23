#!/usr/bin/perl

# Crée des combinaisons plausibles de préfixes et suffixes pour créer
# des noms fictifs à consonnance française (voire espagnole)

# perl scripts/pre_creeNomsFictifs.pl scripts/data/noms-fictifs.lxq

my $prefixes="scripts/data/prefixes-noms.lxq";
my $suffixes="scripts/data/suffixes-noms.lxq";
my $sortie=$ARGV[0];
my @pre=();
my @suf=();
my @final=();


###
# Stockage des préfixes et suffixes

open(E,'<:utf8',$prefixes) or die "Impossible d'ouvrir $prefixes\n";
while (my $l=<E>) { chomp $l; push(@pre,$l); }
close(E);

open(E,'<:utf8',$suffixes) or die "Impossible d'ouvrir $suffixes\n";
while (my $l=<E>) { chomp $l; push(@suf,$l); }
close(E);


###
# Combinaisons

foreach my $p (@pre) {
  foreach my $s (@suf) {
    my $f=""; my $d1=""; my $d2="";
    
    # Extraction de la dernière lettre du préfixe et de la première
    # lettre du suffixe (d1 = première lettre, d2 = lettre entre
    # parenthèses)
    if ($s!~/^([\(])/) { $d1=$1; } elsif ($s=~/^\((.)\)/) { $d2=$1; }
    if ($p=~/(.)$/) { $f=$1; }
    # Si le préfixe se termine par la même lettre que la première
    # entre parenthèses du suffixe, on supprime la lettre entre
    # parenthèses du suffixe, sinon on supprime les parenthèses
    if ($d2 eq $f) { $s=~s/\(.\)//; } else { $s=~s/\(//; $s=~s/\)//; }
    my $ss=$s;
    if (substr($p,length($p)-1) eq substr($s,0,1) && substr($p,length($p)-1)=~/[aeiouys]/ && substr($s,0,1)=~/[aeiouys]/) { $ss=~s/^.//; }
    if ($p eq "Dois" && $s!~/^[aeiouycmnv]/) { next; }

    # Affichage : si le préfixe se termine par une voyelle, le suffixe
    # ne doit pas commencer par une voyelle (sauf "i")
    push(@final,"$p$ss");
    if ($p=~/^[BQ]/) { push(@final,"Le $p$ss"); }
  }
}

open(S,'>:utf8',$sortie);
foreach my $l (sort @final) { print S "$l\n"; }
close(S);
