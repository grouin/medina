# Récupère la colonne de tokens d'un tabulaire, lance le TreeTagger en
# français sur cette colonne en préservant la tokénisation et sans
# enlever de lignes vides (converties en <EOS>), puis intègre les
# colonnes de POS et de lemme dans le tabulaire d'origine, enregistré
# sous un nouveau nom.

# bash ajoute-treetagger.sh input.tab output.tab french/english

cat $1 | cut -f2 | sed "s/^$/<EOS>/; s/^nul$/<SENT>/" >colonne
~/Bureau/outils/treetagger/bin/tree-tagger -token -lemma -sgml ~/Bureau/outils/treetagger/lib/$3.par colonne | sed "s/<EOS>//" | sed "s/<SENT>/<SENT>\t<SENT>\t<SENT>/" | cut -f2,3 >colonne.ttg
cat $1 | cut -f1,2,3,4 >debut
cat $1 | cut -f7,8,9,10,11,12,13,14 >fin
paste debut colonne.ttg fin >$2
cat $2 | awk '{print NF}' | sort | uniq -c
rm debut fin colonne colonne.ttg
