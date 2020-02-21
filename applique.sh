#!/usr/bin/sh
# sh applique.sh tab_test.zero modele-deid

wapiti label -p -m $2 $1 >sortie-zero
perl scripts/post_conversion.pl sortie-zero
perl scripts/conlleval.pl -d '\t' <sortie-zero
