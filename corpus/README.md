# Guide d'annotation

## Classes ##

Gentilé : tout adjectif de localisation (ville, pays) associé à une personne ou une profession (son père juif d'origine [autrichienne]), pas à une organisation (un bar russe) ; la religion n'est pas un gentilé ; les noms de langue non plus


Lieu : tout élément de localisation qui ne constitue pas une adresse ou une organisation (nom de restaurant, d'hôtel)

* si le lieu contient un nom propre, on n'annote que le nom propre : cour du [Louvre], gare d'[Austerlitz], gare [Saint-Lazare], guichets du [Louvre], jardins [Alsace-Lorraine], jardins du [Sacré-Cœur], musée du [Louvre], parc [Monceau], parc [Montsouris], pont de [Bir-Hakeim], pont du [Carrousel], pont [Mirabeau], tour [Montparnasse]

  * si le nom propre renvoie à une ville, l'annoter comme telle : pont de [Puteaux] (ville), Bois de [Boulogne] (ville), gare de [Lyon] (ville)

* en l'absence de nom propre, on ajoute à la portion le type de lieu car l'ensemble de la portion constitue le nom du lieu : [château des Brouillards], [gare du Nord], [gare de l'Est], [Halle aux vins], [jardin des Plantes], [marché aux Puces], [pont des Arts], [poterne des Peupliers], [Rive gauche], [Rive droite]

* les lieudits sont annotés comme "Lieu", sauf s'ils figurent dans un nom de voirie : [Montparnasse], de [Pigalle] aux [Champs-Elysées], Après [Charléty], la [Cité-Universitaire] ; mais pas "place Pigalle" ni "Faubourg Montmartre"

* les portes de Paris sont annotées comme des adresses : [Porte de Clignancourt], [porte d'Italie], [Porte d'Orléans]

* les numéros d'arrondissement, parce qu'ils peuvent être représentés en chiffres romains, avec l'abbréviation d'ordinal (1er, 15ème), sont annotés "Lieu" et non "Code postal" : [9e], [15e arrondissement], [XVe], [XVIe arrondissement]


Organisation :

* les éléments typant l'organisation (clinique, hôpital, café, restaurant) ne sont pas annotés si le nom est un nom propre : hôpital [Rotshschild], hôtel [Castille] ; l'ensemble de la portion est annotée en l'absence de nom propre : [garage de la comète], ou si l'ensemble ne peut être dissocié : [Hôtel de Chicago], [Hôtel Baltimore]

  * test : si la portion annotée, prise seule, n'est plus suffisamment informative, il faut étendre la portion : [comète] (insuffisant) => [garage de la comète]


Profession : seules les professions sont annotées (médecin, pharmacienne), pas les fonctions (client, voisin) ni les titres (abbé, aristocrate, docteur)
