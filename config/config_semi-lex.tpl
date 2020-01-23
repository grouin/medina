*ponct:%t[0,0,"\p"]
*digit:%t[0,0,"\d"]
*ponctM:%m[0,0,"\p"]
*digitM:%m[0,0,"\d"]
*upper:%t[0,0,"^\u"]
*lower:%t[0,0,"^\l"]
*allupper:%t[0,0,"^\u+$"]
*alllower:%t[0,0,"^\l+$"]

UponctAp:%t[0,0,"\p"]/%t[1,0,"\p"]
UdigitAp:%t[0,0,"\d"]/%t[1,0,"\d"]
UponctApM:%m[0,0,"\p"]/%m[1,0,"\p"]
UdigitApM:%m[0,0,"\d"]/%m[1,0,"\d"]
UponctAv:%t[-1,0,"\p"]/%t[0,0,"\p"]
UdigitAv:%t[-1,0,"\d"]/%t[0,0,"\d"]
UponctAvM:%m[-1,0,"\p"]/%m[0,0,"\p"]
UdigitAvM:%m[-1,0,"\d"]/%m[0,0,"\d"]

*taille:%x[0,1]
UtailleAp:%x[0,1]/%x[1,1]
UtailleAv:%x[-1,1]/%x[0,1]

*interv:%x[0,2]
UintervAp:%x[0,2]/%x[1,2]
UintervAv:%x[-1,2]/%x[0,2]

Upos-1:%x[-1,3]
Upos1:%x[1,3]

Udecl:%x[0,4]
Udecl-1:%x[-1,4]

Ufreq:%x[0,5]
Ucons:%x[0,6]
Uvoy:%x[0,7]
Usoundex:%x[0,8]
UnbSyll:%x[0,10]
Uschema:%x[0,11]
Utrigrm:%x[0,12]

BtaillePos:%x[0,2]/%x[0,4]
BdeclUpper:%x[0,5]/%t[0,1,"^\u"]
BupperUpper:%t[0,1,"^\u"]/%t[1,1,"^\u"]
BupperAllUpper:%t[0,1,"^\u"]/%t[1,1,"^\u+$"]

# Ajout affixes
Uprefix:%m[0,1,"^..."]
Usuffix:%m[0,1,"...$"]

*
