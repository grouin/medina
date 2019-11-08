#!/usr/bin/sh

# We assume the existence of BRAT annotations in corpus/train/ and
# corpus/test directories

# Conversion from BRAT to embedded annotations (files *.tag)
# - one argument: path to *{ann,txt} files
perl zero_alignement.pl corpus/train/
perl zero_alignement.pl corpus/test/

# Production of tabular file using the BIO schema for linear chain CRF
# - three arguments: path to embedded annotations files, file
#   extension for those files (tag), and name of output tabular file
perl zero_tabulaire.pl corpus/train/ tag tab_train.zero
perl zero_tabulaire.pl corpus/test/ tag tab_test.zero

# Statistical model building using the Wapiti tool
wapiti train -a rprop- -1 0.1 -p zero_config.tpl tab_train.zero modele-zero

# Model application on test data
wapiti label -p -m modele-zero tab_test.zero >sortie-zero

# Prediction output evaluation (script from the conll challenge)
perl conlleval.pl -d '\t' <sortie-zero

# False positive and false negative analysis
perl post_differences.pl sortie-zero
