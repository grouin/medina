#!/usr/bin/sh

# We assume the existence of BRAT annotations (*txt and *ann files) in
# train and test directories (in this demonstration, we use the files
# we provided in corpus/clinique/jorf/ repository (French Official
# Journal annotated documents)

# Creation of a list in data/ directory of forms, lemma, and POS
# tags, based on lists produced by ABU CNAM, and named
# forme-lemme-pos.tab (to be done only once)
#bash scripts/pre_creeDictionnaire.bash
#perl scripts/pre_releveNgrammes.pl

# Conversion from BRAT to embedded annotations (files *.tag)
# - one argument: path to *{ann,txt} files
perl scripts/zero_alignement.pl corpus/clinique/jorf/train/
perl scripts/zero_alignement.pl corpus/clinique/jorf/test/

# Production of tabular file using the BIO schema for linear chain CRF
# - four arguments: path to embedded annotations files, file extension
#   for those files (tag), name of output tabular file, and type of
#   annotation schema to be used (IO BIO BIO2 BIO2H BWEMO BWEMO+)
# - in addition, a fifth argument may be used to indicate all labels
#   to be kept in the tabular file; e.g., Personne,Ville to only keep
#   annotations of Persons and Towns; if this argument is not used,
#   all existing annotations will be kept
# - annotation schema BIO2 is the schema commonly used (default value)
#   but we achieved better results using the BWEMO+ annotation schema
perl scripts/zero_tabulaire.pl corpus/clinique/jorf/train/ tag tab_train.zero BWEMO+
perl scripts/zero_tabulaire.pl corpus/clinique/jorf/test/ tag tab_test.zero BWEMO+

# Check-up of produced tabular files
perl scripts/pre_verification-tabulaire.pl tab_train.zero
perl scripts/pre_verification-tabulaire.pl tab_test.zero

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
perl scripts/crf-output-splitter.pl sortie-zero output
mkdir brat/
cp corpus/clinique/jorf/test/*txt brat/
cp output/*sgml brat/
perl scripts/conversion-brat.pl brat/
#cp brat/*{ann,txt} path/to/brat/data/


# Post-processing steps to pseudonymize texts, based on previously
# identified entities (date shiffting in the past, pseudonyms for
# person names, fake phone number, and replacement of other
# predictions by a generic tag)
perl scripts/post_antidatation.pl -r output/ -e sgml
perl scripts/post_pseudonymization.pl -r output/ -e dat


rm corpus/clinique/jorf/{train,test}/*tag
rm output/*{dat,dat.log}



################################################################
#
# To train a model specifically for one category, and to force Wapiti
# decoding using two models, use the following steps:
#

perl scripts/zero_alignement.pl corpus/clinique/jorf/train/
perl scripts/zero_tabulaire.pl corpus/clinique/jorf/train/ tag tab_train.zero BWEMO+ Personne
perl scripts/zero_supprimeO.pl tab_train.zero 40 >tab_reduc.zero
time wapiti train -t 2 -a rprop- -1 1 -c -p config/config_zero.tpl tab_reduc.zero modele-Pers
wapiti label -p -m modele-Pers tab_test.zero | perl -ne "s/O$/NUL/; print $_" >temp
wapiti label --force -p -m modele-deid temp >temp2
cat temp2 | cut -f 1,2,3,4,5,6,7,8,9,10,11,12,13,14,16 >sortie-zero
perl scripts/post_conversion.pl sortie-zero
perl scripts/conlleval.pl -d '\t' <sortie-zero
perl scripts/crf-output-splitter.pl sortie-zero output
rm temp*



################################################################
#
# To train a model on new data (in-house data) reusing the existing
# deid model (in order to combine existing performances with new ones
# from the new dataset), we need to check there is no new labels (no
# new classes may be used). We assume the new annotated data (*txt and
# *ann files) are in the "input" folder:
#

perl scripts/zero_alignement.pl input/
perl scripts/zero_tabulaire.pl input/ tag tab_train.zero BWEMO+
perl scripts/zero_supprimeO.pl tab_train.zero 17 >tab_reduc.zero
perl scripts/poursuiteEntrainement.pl tab_reduc.zero
wapiti train -t 2 -a rprop- -1 1 -c tab_reduc.zero -m modele-deid modele-inhouse
wapiti label -p -m modele-inhouse tab_test.zero >sortie-zero
perl scripts/crf-output-splitter.pl sortie-zero output
perl scripts/conlleval.pl -d '\t' <sortie-zero

rm tab_train.zero tab_reduc.zero
