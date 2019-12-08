#!/usr/bin/bash

for i in {a..z}; do wget http://abu.cnam.fr/cgi-bin/donner-dico-uncompress?liste_$i -O data/liste-$i; done
for i in $(ls data/liste*); do cat $i | egrep "\t" | awk -F '\t' '{print $1}' | sort | uniq >>data/dictionnaire-fr.lxq; done
