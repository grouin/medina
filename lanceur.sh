#!/usr/bin/sh

# We assume the existence of BRAT annotations in train and test
# directories

# Creation of a list in data/ directory of forms, lemma, and POS
# tags, based on lists produced by ABU CNAM, and named
# forme-lemme-pos.tab (to be done only once)
#bash creeDictionnaire.bash

# Conversion from BRAT to embedded annotations (files *.tag)
# - one argument: path to *{ann,txt} files
perl zero_alignement.pl corpus/jorf/train/
perl zero_alignement.pl corpus/jorf/test/

# Production of tabular file using the BIO schema for linear chain CRF
# - four arguments: path to embedded annotations files, file extension
#   for those files (tag), name of output tabular file, and type of
#   annotation schema to be used (IO BIO BIO2 BWEMO BWEMO+)
# - annotation schema BIO2 is the schema commonly used (default value)
perl zero_tabulaire.pl corpus/jorf/train/ tag tab_train.zero BWEMO+
perl zero_tabulaire.pl corpus/jorf/test/ tag tab_test.zero BWEMO+

# Statistical model building using the Wapiti tool
wapiti train -t 2 -a rprop- -1 0.1 -p zero_config.tpl tab_train.zero modele-zero

# Model application on test data
wapiti label -p -m modele-zero tab_test.zero >sortie-zero

# Prediction output evaluation (script from the conll challenge)
perl conlleval.pl -d '\t' <sortie-zero

# False positive and false negative analysis
#perl post_differences.pl sortie-zero
