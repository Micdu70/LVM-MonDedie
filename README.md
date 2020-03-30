# Script d'installation & gestion LVM

Une partition /home séparé est indispensable pour l'installation !

La partie "Gestion" fonctionne sur VG préexistant, la détection du nom est automatique.

## Utilisation
````
apt-get update && apt-get upgrade -y
apt-get install git-core -y

cd /tmp
git clone https://github.com/Micdu70/LVM-MonDedie
cd LVM-MonDedie
chmod a+x lvm-mondedie.sh && ./lvm-mondedie.sh
````

**Auteur :** Ex_Rat
**Version modifiée par Micdu70**

Adapté du tuto de Xataz pour mondedie.fr disponible ici:
http://mondedie.fr/viewtopic.php?id=7147

**License**
This work is licensed under a [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-nc-sa/4.0/)
