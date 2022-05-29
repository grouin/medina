*ponct:%t[0,1,"\p"]
*digit:%t[0,1,"\d"]
*ponctM:%m[0,1,"\p"]
*digitM:%m[0,1,"\d"]
*upper:%t[0,1,"^\u"]
*lower:%t[0,1,"^\l"]
*allupper:%t[0,1,"^\u+$"]
*alllower:%t[0,1,"^\l+$"]

Uvirgule:%t[0,1,"\,"]
Upoint:%t[0,1,"\."]
Uegal:%t[0,1,"\="]

UponctAp:%t[0,1,"\p"]/%t[1,1,"\p"]
UdigitAp:%t[0,1,"\d"]/%t[1,1,"\d"]
UponctApM:%m[0,1,"\p"]/%m[1,1,"\p"]
UdigitApM:%m[0,1,"\d"]/%m[1,1,"\d"]
UponctAv:%t[-1,1,"\p"]/%t[0,1,"\p"]
UdigitAv:%t[-1,1,"\d"]/%t[0,1,"\d"]
UponctAvM:%m[-1,1,"\p"]/%m[0,1,"\p"]
UdigitAvM:%m[-1,1,"\d"]/%m[0,1,"\d"]

Utaille:%x[0,2]
UtailleAp:%x[0,2]/%x[1,2]
UtailleAv:%x[-1,2]/%x[0,2]

Uinterv:%x[0,3]
UintervAp:%x[0,3]/%x[1,3]
UintervAv:%x[-1,3]/%x[0,3]

Upos-1:%x[-1,4]
Upos:%x[0,4]
Upos1:%x[1,4]

Udecl:%x[0,5]
Udecl-1:%x[-1,5]

Ufreq:%x[0,6]
Ucons:%x[0,7]
Uvoy:%x[0,8]
#Usoundex:%x[0,9]
UnbSyll:%x[0,10]
#Uschema:%x[0,11]
Utrigrm:%x[0,12]

UtaillePos:%x[0,2]/%x[0,4]
UdeclUpper:%x[0,5]/%t[0,1,"^\u"]
UupperUpper:%t[0,1,"^\u"]/%t[1,1,"^\u"]
UupperAllUpper:%t[0,1,"^\u"]/%t[1,1,"^\u+$"]

Usignal:%t[-2,1,"signal"]/%t[-1,1,"de"]
Uscore:%t[-2,1,"score"]/%t[-1,1,"de"]

UdeclPers:%t[-1,1,"docteur"]
UdeclPers:%t[-1,1,"Docteur"]
UdeclPers:%t[-1,1,"Dr"]
UdeclPers:%t[-1,1,"madame"]
UdeclPers:%t[-1,1,"Madame"]
UdeclPers:%t[-1,1,"Mme"]
UdeclPers:%t[-1,1,"Mmes"]
UdeclPers:%t[-1,1,"monsieur"]
UdeclPers:%t[-1,1,"Monsieur"]
UdeclPers:%t[-1,1,"M\."]
UdeclPers:%t[-1,1,"Mr"]
UdeclPers:%t[-1,1,"Pr"]
UdeclPers:%t[-1,1,"professeur"]
UdeclPers:%t[-1,1,"Professeur"]
UdeclPers:%t[-1,1,"Mademoiselle"]
UdeclPers:%t[-1,1,"Melle"]
UdeclPers:%t[-1,1,"Mlle"]
UdeclPers:%t[-1,1,"Mle"]

# Ajout token
*contextL:%x[-1,1]/%x[0,1]
*tokenAv:%x[-1,1]
*token:%x[0,1]
*tokenAp:%x[1,1]
*contextR:%x[0,1]/%x[1,1]
Uprefix:%m[0,1,"^..."]
Usuffix:%m[0,1,"...$"]

*
