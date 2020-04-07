#!/usr/bin/sh

tar -xvf modele-deid.tar.gz

# To perform an automatic de-identification, simply add *.txt files to
# be de-identified into the "fichiers" folder and process the
# following stages:

perl scripts/zero_tabulaire.pl fichiers/ txt tab_test.zero BWEMO+
wapiti label -p -m modele-deid tab_test.zero >sortie-zero
perl scripts/crf-output-splitter.pl sortie-zero

# The *.sgml files in the "fichiers" folder correspond to the original
# *.txt files for which identifying data found have been
# tagged. Either a human user complete annotations within those files
# (namely, false positive and false negative), or the following stages
# are made to replace dates and person names by realistic fake data.

perl scripts/post_antidatation.pl -r fichiers/ -e sgml
perl scripts/post_pseudonymization.pl -r fichiers/ -e dat

# De-identified files are *.pse files
