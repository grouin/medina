# Relève les tri-grammes de caractères depuis la liste des formes
# fléchies du français et génère une liste de trigrammes avec leur
# fréquence d'utilisation dans cette liste

use utf8;

my $fichier="scripts/data/forme-lemme-pos.tab";
my $nbTot=0;
my %voc=();

open(E,$fichier) or die "Impossible d'ouvrir $fichier\n";
while (my $l=<E>) {
  chomp $l;
  $l=lc($l);
  my ($token,$lemme,$pos)=split(/\t/,$l);
  for (my $i=0;$i<length($token)-2;$i++) {
    my $ngr=substr($token,$i,3);
    if ($ngr=~/^\p{L}{3}$/) { $nbTot++; $voc{$ngr}++; }
  }
}
close(E);

open(S,'>:utf8',"scripts/data/liste_ngrammes.txt");
foreach my $ngr (sort keys %voc) { print S "$ngr\t",sprintf("%.9f",$voc{$ngr}/$nbTot)*1000,"\n"; }
close(S);
