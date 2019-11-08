# MEDINA (règles, v2)

MEDical INformation Anonymization

## Documentation ##

This is a rule-based version of the MEDINA toolkit.

Files:

* config.ano: main configuration file

* 9_medina.pl: main script

* anonymisation-fr.grm: grammar used to de-identify French clinical texts

* data/: several files of last names, first names, names of country and town

Remark: this script has been successfully used in 2013 but several PERL functions are now deprecated (especially for hash tables) and make it no longer usable...