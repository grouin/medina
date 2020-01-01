#!/usr/bin/sh

# We assume the existence of BRAT annotations in train and test
# directories

# Creation of a list in data/ directory of forms, lemma, and POS
# tags, based on lists produced by ABU CNAM, and named
# forme-lemme-pos.tab (to be done only once)
#bash pre_creeDictionnaire.bash

# Conversion from BRAT to embedded annotations (files *.tag)
# - one argument: path to *{ann,txt} files
perl zero_alignement.pl corpus/jorf/train/
perl zero_alignement.pl corpus/jorf/test/

# Production of tabular file using the BIO schema for linear chain CRF
# - four arguments: path to embedded annotations files, file extension
#   for those files (tag), name of output tabular file, and type of
#   annotation schema to be used (IO BIO BIO2 BIO2H BWEMO BWEMO+)
# - annotation schema BIO2 is the schema commonly used (default value)
perl zero_tabulaire.pl corpus/jorf/train/ tag tab_train.zero BWEMO+
perl zero_tabulaire.pl corpus/jorf/test/ tag tab_test.zero BWEMO+

# Over-training reduction by deletion of unannotated lines when those
# lines are not in a local context of annotated lines (e.g., more than
# 17 lines). The output consists in a new tabular file with less
# unannotated lines, to be used to train the model in the next
# step. Only for the training stage
#perl zero_supprimeO.pl tab_train.zero 17 >tab_reduc.zero

# Statistical model building using the Wapiti tool
wapiti train -t 2 -a rprop- -1 0.1 -p config_zero.tpl tab_train.zero modele-zero

# Model application on test data
wapiti label -p -m modele-zero tab_test.zero >sortie-zero

# Prediction output evaluation (script from the conll challenge)
perl post_conversion.pl sortie-zero
perl conlleval.pl -d '\t' <sortie-zero

# False positive and false negative analysis
#perl post_differences.pl sortie-zero

# Single annotated files production from output (files *sgml in test/)
perl crf-output-splitter.pl sortie-zero
#mkdir brat/
#cp corpus/jorf/test/*{txt,sgml} brat/
#perl conversion-brat.pl brat/
#cp brat/*{ann,txt} path/to/brat/data/


# Post-processing steps to pseudonymize texts, based on previously
# identified entities (date shiffting in the past, pseudonyms for
# person names, fake phone number, and replacement of other
# predictions by a generic tag)
perl post_antidatation.pl -r corpus/jorf/test/ -e sgml
perl post_pseudonymization.pl -r corpus/jorf/test/ -e dat
