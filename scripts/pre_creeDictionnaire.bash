#!/usr/bin/bash

for i in {a..z}; do wget http://abu.cnam.fr/cgi-bin/donner-dico-uncompress?liste_$i -O scripts/data/liste-$i; done
for i in $(ls scripts/data/liste*); do cat $i | awk "/\t/" | sort | uniq >>scripts/data/forme-lemme-pos.tab; done
