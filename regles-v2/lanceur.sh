###
# Dictionnaire des formes fléchies du français (à ne faire que la première fois)

bash creeDictionnaire.sh


###
# MEDINA règle, première version (indisponible sous GitHub)
#perl 1k_balisage.pl -r corpus/ -e txt
#perl 2_antidatation.pl -r corpus/
#perl 4_pseudonymes.pl -r corpus/ -e dat
#perl 5_hyperonymes.pl -r corpus/ -e pse

#rm corpus/*{med,dat,log,pse}


###
# MEDINA règle, deuxième version
perl 9_medina.pl -r corpus/ -e txt 
perl 2_antidatation.pl -r corpus/
perl 4_pseudonymes.pl -r corpus/ -e dat
perl 5_hyperonymes.pl -r corpus/ -e pse

rm corpus/*{med,dat,log,pse}
