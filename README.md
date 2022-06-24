# medina
Medical Information Anonymization

## Documentation ##

MEDINA is a toolbox to de-identify texts, originally designed for
clinical texts. This toolbox aims at de-identifying data using linear
chain CRF (Wapiti tool, see https://github.com/Jekub) and producing
delexicalized statistical models, i.e., without any form of surface
(strictly no learning of tokens, but basic features based on tokens
are used: upper/lower case, presence of digits, punctuation marks,
etc.) in order to share models (since there is no nominative data in
the models).

Files:

* lanceur.sh: all useful commands to process the data (assuming
  existing annotated data in corpus/appr/ and corpus/test/ files
  containing both *{ann,txt} files)

* desidentification.sh: all usef commands to de-identify *txt files
  (no evaluation will be made, assuming there is no gold standard)

* scripts/pre_creeDictionnaire.bash: produces forme-lemme-pos.tab file
  in the data directory (list of forms, lemmas, and POS for French,
  from CNAM data); to be done only once

* scripts/pre_releveNgrammes.pl: from the previous dictionary,
  computes absolute frequency of trigrams of characters for French and
  produces a liste_ngrammes.txt file into the scripts/data/ folder

* scripts/zero_alignement.pl: converts BRAT annotations into embedded
  annotations (*.tag files are created); allows to manage both layered
  and discontinuous entities

* scripts/zero_tabulaire.pl: produces tabular files based on previous
  files, using a schema useful for CRF tools among following available
  ones: IO, BIO, BIO2, BIO2H, BWEMO, or BWEMO+

* scripts/pre_verification-tabulaire.pl: check if the produced tabular
  is safe for the Medina toolkit; unexpected annotations will be shown

* scripts/zero_supprimeO.pl: allows to remove unannotated lines in
  order to reduce the over-training of the O category; a context of 17
  lines surrounding annotations seems to be useful; for mono-category
  models, this context must be extended (e.g., 40 lines) in order to
  ensure correct precision values

* config/config_zero.tpl: configuration template for Wapiti tool (for
  experiments based on semi-lexicalized, or fully lexicalized models,
  two other configuration files are given: config_lex.tpl and
  config_semi-lex.tpl)

* scripts/post_lexique.pl: applies the content of lexique.tab file
  (two columns: class and phrase) on the prediction files in order to
  complete the annotations (BWEMO annotation schema). Three arguments:
  -r (repository to prediction file: ./), -e (file extension of the
  input file: wap), -s (file extension of the output file: out)

* scripts/post_conversion.pl: converts the prediction file from BWEMO+
  annotation schema to BIO2 annotation schema in order to perform an
  evaluation using the conneval.pl evaluation script

* scripts/post_differences.pl: highlights false positive and false
  negative from the prediction file produced by Wapiti

* scripts/crf-output-splitter.pl: allows to split the prediction file
  into single files, reproducing the original content (in terms of
  spaces and line breaks); predictions are represented with embedded
  tags; please indicate the output folder as 2nd argument

* scripts/post_antidatation.pl: random date shiffting based on
  previously identified dates

* scripts/post_pseudonymization.pl: pseudonymizes (1) person names
  based on lists of common first names and last names used in France
  and Québec, (2) city names, based on a list of cities from France,
  and (3) produces fake phone numbers

* scripts/post_combineColonnes.pl: merges several columns of
  predictions when mono-category models are used

* scripts/post_description.pl: based on the tagged files (*sgml),
  transforms all tokens in basic POS+case information but keeps some
  digit (not in dates) and trigger words; allows to highlight basic
  linguistic structures in processed files, either to improve scripts
  or to describe how a clinical document is made (tentative)

* scripts/transformeCaracteres.pl: transforms all characters from *txt
  files into another characters from the same type (a vowel by another
  vowel, a consonnant by another consonnant)


## Commands ##

The following commands allow:

* to train a CRF model based on existing BRAT annotations found in
  corpus/jorf/train/ (input training data)

* to apply this model on texts from corpus/jorf/test/ (input test
  data)

* to evaluate output predictions (assuming gold standard annotations
  exist for the test dataset)

* and to produce de-identified single files in the output folder named
  "output/", composed of fake phone numbers and pseudonymized person
  names and city names; other types of identified information are
  masked by a generic tag indicating the type of information.

These are end-to-end commands:

	bash scripts/pre_creeDictionnaire.bash
	perl scripts/pre_releveNgrammes.pl

	perl scripts/zero_alignement.pl corpus/jorf/train/
	perl scripts/zero_alignement.pl corpus/jorf/test/
	
	perl scripts/zero_tabulaire.pl corpus/jorf/train/ tag tab_train.zero BWEMO+
	perl scripts/zero_tabulaire.pl corpus/jorf/test/ tag tab_test.zero BWEMO+

	perl scripts/pre_verification-tabulaire.pl tab_train.zero
	perl scripts/pre_verification-tabulaire.pl tab_test.zero
	
	wapiti train -t 2 -a rprop- -1 1 -p config_zero.tpl tab_train.zero modele-zero
	wapiti label -p -m modele-zero tab_test.zero >sortie-zero.wap

	perl scripts/post_lexique.pl -r ./ -e wap -s out
	perl scripts/post_conversion.pl sortie-zero.out
	perl scripts/conlleval.pl -d '\t' <sortie-zero.out
	
	perl scripts/crf-output-splitter.pl sortie-zero.out output
	perl scripts/post_antidatation.pl -r output/ -e sgml
	perl scripts/post_pseudonymization.pl -r output/ -e dat


## How to automatically de-identify files? ##

Simply add *.txt files (clinical texts written in French) into a
folder (e.g., a "input" folder) and perform the following stages:

	bash scripts/pre_creeDictionnaire.bash
	perl scripts/pre_releveNgrammes.pl

	tar -xvzf modele-deid.tar.gz
	perl scripts/zero_tabulaire.pl input/ txt tab_test.zero BWEMO+
	wapiti label -p -m modele-deid tab_test.zero >sortie-zero.wap
	perl scripts/crf-output-splitter.pl sortie-zero.wap output
	perl scripts/post_antidatation.pl -r output/ -e sgml
	perl scripts/post_pseudonymization.pl -r output/ -e dat

Final de-identified files are *.pse files in the "output/" folder.
Alternatively, you can check the *sgml files from the "output/"
folder by adding or removing opening and closing tags for identifying
information, and then to perform the two last stages.


## License ##

This toolbox is licenced under the term of the two-clause BSD Licence:

    Copyright (c) 2020 CNRS
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions
    are met:
        * Redistributions of source code must retain the above
          copyright notice, this list of conditions and the following
          disclaimer.
        * Redistributions in binary form must reproduce the above
          copyright notice, this list of conditions and the following
          disclaimer in the documentation and/or other materials
          provided with the distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
    CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
    INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
    MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
    BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
    EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
    TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
    ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
    TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
    THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
    SUCH DAMAGE.

## Contact ##

For help and feedback please contact the author below:

* Grouin Cyril       &lt;cyril.grouin@limsi.fr&gt;
