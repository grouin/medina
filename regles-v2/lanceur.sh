###
# MEDINA règle, première version
perl 1k_balisage.pl -r corpus/ -e txt
perl 2_antidatation.pl -r corpus/
perl 4_pseudonymes.pl -r corpus/ -e dat -l 76
perl 5_hyperonymes.pl -r corpus/ -e pse

rm corpus/*{med,dat,log,pse,hyp}


###
# MEDINA règle, deuxième version
perl 9_medina.pl -r corpus/ -e txt 
perl 2_antidatation.pl -r corpus/
perl 4_pseudonymes.pl -r corpus/ -e dat -l 76
perl 5_hyperonymes.pl -r corpus/ -e pse

rm corpus/*{med,dat,log,pse,hyp}
