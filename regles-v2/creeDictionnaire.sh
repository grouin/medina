wget http://abu.cnam.fr/cgi-bin/donner-dico-uncompress?liste_a -O data/liste-a
wget http://abu.cnam.fr/cgi-bin/donner-dico-uncompress?liste_b -O data/liste-b
wget http://abu.cnam.fr/cgi-bin/donner-dico-uncompress?liste_c -O data/liste-c
wget http://abu.cnam.fr/cgi-bin/donner-dico-uncompress?liste_d -O data/liste-d
wget http://abu.cnam.fr/cgi-bin/donner-dico-uncompress?liste_e -O data/liste-e
wget http://abu.cnam.fr/cgi-bin/donner-dico-uncompress?liste_f -O data/liste-f
wget http://abu.cnam.fr/cgi-bin/donner-dico-uncompress?liste_g -O data/liste-g
wget http://abu.cnam.fr/cgi-bin/donner-dico-uncompress?liste_h -O data/liste-h
wget http://abu.cnam.fr/cgi-bin/donner-dico-uncompress?liste_i -O data/liste-i
wget http://abu.cnam.fr/cgi-bin/donner-dico-uncompress?liste_j -O data/liste-j
wget http://abu.cnam.fr/cgi-bin/donner-dico-uncompress?liste_k -O data/liste-k
wget http://abu.cnam.fr/cgi-bin/donner-dico-uncompress?liste_l -O data/liste-l
wget http://abu.cnam.fr/cgi-bin/donner-dico-uncompress?liste_m -O data/liste-m
wget http://abu.cnam.fr/cgi-bin/donner-dico-uncompress?liste_n -O data/liste-n
wget http://abu.cnam.fr/cgi-bin/donner-dico-uncompress?liste_o -O data/liste-o
wget http://abu.cnam.fr/cgi-bin/donner-dico-uncompress?liste_p -O data/liste-p
wget http://abu.cnam.fr/cgi-bin/donner-dico-uncompress?liste_q -O data/liste-q
wget http://abu.cnam.fr/cgi-bin/donner-dico-uncompress?liste_r -O data/liste-r
wget http://abu.cnam.fr/cgi-bin/donner-dico-uncompress?liste_s -O data/liste-s
wget http://abu.cnam.fr/cgi-bin/donner-dico-uncompress?liste_t -O data/liste-t
wget http://abu.cnam.fr/cgi-bin/donner-dico-uncompress?liste_u -O data/liste-u
wget http://abu.cnam.fr/cgi-bin/donner-dico-uncompress?liste_v -O data/liste-v
wget http://abu.cnam.fr/cgi-bin/donner-dico-uncompress?liste_w -O data/liste-w
wget http://abu.cnam.fr/cgi-bin/donner-dico-uncompress?liste_x -O data/liste-x
wget http://abu.cnam.fr/cgi-bin/donner-dico-uncompress?liste_y -O data/liste-y
wget http://abu.cnam.fr/cgi-bin/donner-dico-uncompress?liste_z -O data/liste-z

cat data/liste-a | egrep "\t" | awk -F '\t' '{print $1}' | sort | uniq >data/dictionnaire-fr.lxq
cat data/liste-b | egrep "\t" | awk -F '\t' '{print $1}' | sort | uniq >>data/dictionnaire-fr.lxq
cat data/liste-c | egrep "\t" | awk -F '\t' '{print $1}' | sort | uniq >>data/dictionnaire-fr.lxq
cat data/liste-d | egrep "\t" | awk -F '\t' '{print $1}' | sort | uniq >>data/dictionnaire-fr.lxq
cat data/liste-e | egrep "\t" | awk -F '\t' '{print $1}' | sort | uniq >>data/dictionnaire-fr.lxq
cat data/liste-f | egrep "\t" | awk -F '\t' '{print $1}' | sort | uniq >>data/dictionnaire-fr.lxq
cat data/liste-g | egrep "\t" | awk -F '\t' '{print $1}' | sort | uniq >>data/dictionnaire-fr.lxq
cat data/liste-h | egrep "\t" | awk -F '\t' '{print $1}' | sort | uniq >>data/dictionnaire-fr.lxq
cat data/liste-i | egrep "\t" | awk -F '\t' '{print $1}' | sort | uniq >>data/dictionnaire-fr.lxq
cat data/liste-j | egrep "\t" | awk -F '\t' '{print $1}' | sort | uniq >>data/dictionnaire-fr.lxq
cat data/liste-k | egrep "\t" | awk -F '\t' '{print $1}' | sort | uniq >>data/dictionnaire-fr.lxq
cat data/liste-l | egrep "\t" | awk -F '\t' '{print $1}' | sort | uniq >>data/dictionnaire-fr.lxq
cat data/liste-m | egrep "\t" | awk -F '\t' '{print $1}' | sort | uniq >>data/dictionnaire-fr.lxq
cat data/liste-n | egrep "\t" | awk -F '\t' '{print $1}' | sort | uniq >>data/dictionnaire-fr.lxq
cat data/liste-o | egrep "\t" | awk -F '\t' '{print $1}' | sort | uniq >>data/dictionnaire-fr.lxq
cat data/liste-p | egrep "\t" | awk -F '\t' '{print $1}' | sort | uniq >>data/dictionnaire-fr.lxq
cat data/liste-q | egrep "\t" | awk -F '\t' '{print $1}' | sort | uniq >>data/dictionnaire-fr.lxq
cat data/liste-r | egrep "\t" | awk -F '\t' '{print $1}' | sort | uniq >>data/dictionnaire-fr.lxq
cat data/liste-s | egrep "\t" | awk -F '\t' '{print $1}' | sort | uniq >>data/dictionnaire-fr.lxq
cat data/liste-t | egrep "\t" | awk -F '\t' '{print $1}' | sort | uniq >>data/dictionnaire-fr.lxq
cat data/liste-u | egrep "\t" | awk -F '\t' '{print $1}' | sort | uniq >>data/dictionnaire-fr.lxq
cat data/liste-v | egrep "\t" | awk -F '\t' '{print $1}' | sort | uniq >>data/dictionnaire-fr.lxq
cat data/liste-w | egrep "\t" | awk -F '\t' '{print $1}' | sort | uniq >>data/dictionnaire-fr.lxq
cat data/liste-x | egrep "\t" | awk -F '\t' '{print $1}' | sort | uniq >>data/dictionnaire-fr.lxq
cat data/liste-y | egrep "\t" | awk -F '\t' '{print $1}' | sort | uniq >>data/dictionnaire-fr.lxq
cat data/liste-z | egrep "\t" | awk -F '\t' '{print $1}' | sort | uniq >>data/dictionnaire-fr.lxq
