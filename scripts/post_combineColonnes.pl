# Si même étiquette dans toutes les colonnes, on n'en garde qu'une
# Si étiquettes différentes, on garde la non-nulle
# Si plusieurs étiquettes non-nulles, on priorise les étiquettes

my $fichier=$ARGV[0];

open(E,$fichier);
while (my $ligne=<E>) {
  chomp $ligne;
  my @tags=split(/\t/,$ligne);
  my %tri=();
  my $label="";
  foreach my $tag (@tags) { $tri{$tag}++; }
  foreach my $tag (sort keys %tri) { $label.=$tag; }
  
  # B-XxxNUL -> B-Xxx ; NULO-EOS -> O-EOS
  $label=~s/([BE]\-.*)(NUL|O-EOS)/$1/g;
  $label=~s/(O-EOS|NUL)([OMW]\-)/$2/g;
  $label=~s/(O-EOS|NUL)([OMW])\-Date/$2\-Date/g;
  $label=~s/([BWEM]-\w*)(O-\w*)/$1/g;
  $label=~s/(O-\w*)([BWEM]-\w*)/$2/g;
  $label=~s/([BWEM]-\w*)NUL/$1/g;
  # Adresse>Ville, Date>Téléphone, Lieu<Ville
  $label=~s/([BWEMO]\-Adresse)[BWEMO]\-Ville/$1/;
  $label=~s/[BWEMO]\-Ville([BWEMO]\-Adresse)/$1/;
  $label=~s/([BWEMO]\-Date)[BWEMO]\-Telephone/$1/;
  $label=~s/[BWEMO]\-Lieu([BWEMO]\-Ville)/$1/;

  print "$label\n";
}
close(E);
