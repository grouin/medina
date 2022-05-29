#!/usr/bin/sh

tar -xvf modele-deid.tar.gz

# To perform an automatic de-identification, simply add *.txt files to
# be de-identified into the "input" folder and process the
# following stages:

perl scripts/zero_tabulaire.pl input/ txt tab_test.zero BWEMO+
wapiti label -p -m modele-deid tab_test.zero >sortie-zero
perl scripts/crf-output-splitter.pl sortie-zero output

# The *.sgml files in the "output" folder correspond to the original
# *.txt files for which identifying data found have been
# tagged. Either a human user complete annotations within those files
# (namely, false positive and false negative), or the following stages
# are made to replace dates and person names by realistic fake
# data. For a given number of days, use -n 1234 (where 1234 is the
# number of days to shift in the past). For keeping tags surrounding
# dates, use -m

perl scripts/post_antidatation.pl -r output/ -e sgml -n 1234 -m
perl scripts/post_pseudonymization.pl -r output/ -e dat

# De-identified files are *.pse files
