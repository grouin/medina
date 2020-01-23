*ponct:%t[0,1,"\p"]
*digit:%t[0,1,"\d"]
*ponctM:%m[0,1,"\p"]
*digitM:%m[0,1,"\d"]
*upper:%t[0,1,"^\u"]
*lower:%t[0,1,"^\l"]
*allupper:%t[0,1,"^\u+$"]
*alllower:%t[0,1,"^\l+$"]

UponctAp:%t[0,1,"\p"]/%t[1,1,"\p"]
UdigitAp:%t[0,1,"\d"]/%t[1,1,"\d"]
UponctApM:%m[0,1,"\p"]/%m[1,1,"\p"]
UdigitApM:%m[0,1,"\d"]/%m[1,1,"\d"]
UponctAv:%t[-1,1,"\p"]/%t[0,1,"\p"]
UdigitAv:%t[-1,1,"\d"]/%t[0,1,"\d"]
UponctAvM:%m[-1,1,"\p"]/%m[0,1,"\p"]
UdigitAvM:%m[-1,1,"\d"]/%m[0,1,"\d"]

*taille:%x[0,2]
UtailleAp:%x[0,2]/%x[1,2]
UtailleAv:%x[-1,2]/%x[0,2]

*interv:%x[0,3]
UintervAp:%x[0,3]/%x[1,3]
UintervAv:%x[-1,3]/%x[0,3]

Upos-1:%x[-1,4]
Upos1:%x[1,4]

Udecl:%x[0,5]
Udecl-1:%x[-1,5]

Ufreq:%x[0,6]
Ucons:%x[0,7]
Uvoy:%x[0,8]
#Usoundex:%x[0,9]
UnbSyll:%x[0,10]
Uschema:%x[0,11]

BtaillePos:%x[0,2]/%x[0,4]
BdeclUpper:%x[0,5]/%t[0,1,"^\u"]
BupperUpper:%t[0,1,"^\u"]/%t[1,1,"^\u"]
BupperAllUpper:%t[0,1,"^\u"]/%t[1,1,"^\u+$"]

*
