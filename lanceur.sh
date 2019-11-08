#!/usr/bin/sh

# On suppose que des corpus d'apprentissage et de test annotés avec
# BRAT existent dans des répertoires corpus/appr/ et corpus/test/

# Conversion du format BRAT vers un format d'annotations embarquées
# (fichiers *.tag)
# - un argument : chemin vers les fichiers *{ann,txt}
perl zero_alignement.pl corpus/appr/
perl zero_alignement.pl corpus/test/

# Production du tabulaire au format BIO pour les CRF de chaîne
# linéaire
# - trois arguments : chemin vers les fichiers d'annotations
#   embarquées, extension de ces fichiers (tag), et nom des tabulaires
#   produits en sortie
perl zero_tabulaire.pl corpus/appr/ tag tab_train.zero
perl zero_tabulaire.pl corpus/test/ tag tab_test.zero

# Construction du modèle statistique avec Wapiti sur les données
# d'apprentissage
wapiti train -a rprop- -1 0.1 -p zero_config.tpl tab_train.zero modele-zero

# Décodage des données de test
wapiti label -p -m modele-zero tab_test.zero >sortie-zero

# Evaluation des prédictions du modèle (script des campagnes
# d'évaluation conll)
perl conlleval.pl -d '\t' <sortie-zero

# Affichage des faux positifs et faux négatifs pour analyse
perl post_differences.pl sortie-zero
