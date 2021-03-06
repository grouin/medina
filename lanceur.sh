#!/usr/bin/sh

# We assume the existence of BRAT annotations in train and test
# directories

# Creation of a list in data/ directory of forms, lemma, and POS
# tags, based on lists produced by ABU CNAM, and named
# forme-lemme-pos.tab (to be done only once)
#bash scripts/pre_creeDictionnaire.bash
#perl scripts/pre_releveNgrammes.pl

# Conversion from BRAT to embedded annotations (files *.tag)
# - one argument: path to *{ann,txt} files
perl scripts/zero_alignement.pl corpus/jorf/train/
perl scripts/zero_alignement.pl corpus/jorf/test/

# Production of tabular file using the BIO schema for linear chain CRF
# - four arguments: path to embedded annotations files, file extension
#   for those files (tag), name of output tabular file, and type of
#   annotation schema to be used (IO BIO BIO2 BIO2H BWEMO BWEMO+)
# - in addition, a fifth argument may be used to indicate all labels
#   to be kept in the tabular file; e.g., Personne,Ville to only keep
#   annotations of Persons and Towns; if this argument is not used,
#   all existing annotations will be kept
# - annotation schema BIO2 is the schema commonly used (default value)
perl scripts/zero_tabulaire.pl corpus/jorf/train/ tag tab_train.zero BWEMO+
perl scripts/zero_tabulaire.pl corpus/jorf/test/ tag tab_test.zero BWEMO+

# Over-training reduction by deletion of unannotated lines when those
# lines are not in a local context of annotated lines (e.g., more than
# 17 lines). The output consists in a new tabular file with less
# unannotated lines, to be used to train the model in the next
# step. Only for the training stage
perl scripts/zero_supprimeO.pl tab_train.zero 17 >tab_reduc.zero

# Statistical model building using the Wapiti tool
wapiti train -t 2 -a rprop- -1 1 -c -p config/config_zero.tpl tab_reduc.zero modele-zero

# Model application on test data
wapiti label -p -m modele-zero tab_test.zero >sortie-zero

# Prediction output evaluation (script from the conll challenge)
#perl -CSDA scripts/post_propagation.pl sortie-zero >sortie-zero.prop
perl scripts/post_conversion.pl sortie-zero
perl scripts/conlleval.pl -d '\t' <sortie-zero

# False positive and false negative analysis
#perl scripts/post_differences.pl sortie-zero

# Single annotated files production from output (files *sgml in test/)
perl scripts/crf-output-splitter.pl sortie-zero
mkdir brat/
cp corpus/new/*{txt,sgml} brat/
perl scripts/conversion-brat.pl brat/
#cp brat/*{ann,txt} path/to/brat/data/


# Post-processing steps to pseudonymize texts, based on previously
# identified entities (date shiffting in the past, pseudonyms for
# person names, fake phone number, and replacement of other
# predictions by a generic tag)
perl scripts/post_antidatation.pl -r corpus/jorf/test/ -e sgml
perl scripts/post_pseudonymization.pl -r corpus/jorf/test/ -e dat
  



# To train a model specifically for one category, and to force Wapiti
# decoding using two models, use the following steps:
perl scripts/zero_alignement.pl corpus/jorf/sante/train/
perl scripts/zero_tabulaire.pl corpus/jorf/sante/train/ tag tab_train.zero BWEMO+ Personne
perl scripts/zero_supprimeO.pl tab_train.zero 40 >tab_reduc.zero
time wapiti train -t 2 -a sgd-l1 -2 0.1 --eta0 0.05 -c -p config/config_zero.tpl tab_reduc.zero modele-Pers
wapiti label -p -m modele-Pers tab_test.zero | perl -ne "s/O$/NUL/; print $_" >temp
wapiti label --force -p -m modele-deid temp >temp2
cat temp2 | cut -f 1,2,3,4,5,6,7,8,9,10,11,12,13,14,16 >sortie-zero
perl scripts/post_conversion.pl sortie-zero
perl scripts/conlleval.pl -d '\t' <sortie-zero
rm temp*
