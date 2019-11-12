# MEDINA (règles, v2)

MEDical INformation Anonymization, Cyril Grouin

## Documentation ##

This is a rule-based version of the MEDINA toolkit.

Files:

* config: main configuration file, please keep this name "config"

* 9_medina.pl: main script

* anonymisation-fr.grm: grammar used to de-identify French clinical texts

* data/: several files of last names, first names, names of country and town

## Grammar ##

The main principle of this second version of MEDINA relies on a
grammar in which the user defines its own rules. We use the following
syntax in the grammar files:

* variable: $NAME to define, _NAME to use in a rule

  $DAY	(Monday|Tuesday|Wednesday|...|Sunday)
  $DIGIT	[\d]

* rules: tag to be used, tabulation, rule with parenthesis to capture
  the pattern to be tagged

  date	(_DAY _DIGIT+)
  email	([A-Za-z\.\-]+\@[A-Za-z\-\.]+\.[a-z]{2,3})

Class of characters as well as quantifiers can be used in rules, as
for any common regular expression.

## Usage ##

Please consider the content of following files: config (to configure
the script), sample.grm (to de-identify dates and emails), and the
directory corpus/ containing *.txt files on which the script will be
applied to produce *.med files

* perl 9_medina.pl -r corpus/ -e txt

* existing corpus/file.txt:
  Please send an email at firstname.lastname@gmail.com on Tuesday 12 November

* corpus/file.med produced:
  Please send an email at <email>firstname.lastname@gmail.com</email> on <date>Tuesday 12</date> November
