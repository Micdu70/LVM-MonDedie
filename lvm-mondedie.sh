#!/bin/bash
#
# cd /tmp
# git clone https://github.com/exrat/LVM-MonDedie
# cd LVM-MonDedie
# chmod a+x lvm-mondedie.sh && ./lvm-mondedie.sh
#
# Auteur ex_rat
# Adapté du tuto de Xataz pour mondedie.fr http://mondedie.fr/viewtopic.php?id=7147
#
# This work is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License
# http://creativecommons.org/licences/by-nc-sa/4.0

# variables
CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CYELLOW="${CSI}1;33m"
CBLUE="${CSI}1;34m"

# Ne rien modifier, la détection d'un VG existant est automatique
VGNAME="vghome"
DEV="/dev/mapper"
FSTAB="/etc/fstab"

# check packages
if ! command -v "bc" > /dev/null 2>&1 ; then
	apt-get install -y bc
	if ! command -v "bc" > /dev/null 2>&1 ; then
		echo "" ; echo -e "${CRED}L'installation du paquet \"bc\" a échoué${CEND}" ; echo ""
		exit
	fi
fi
if ! command -v "vgcreate" > /dev/null 2>&1 ; then
	apt-get install -y lvm2
	if ! command -v "vgcreate" > /dev/null 2>&1 ; then
		echo "" ; echo -e "${CRED}L'installation du paquet \"lvm2\" a échoué${CEND}" ; echo ""
		exit
	fi
fi

# functions
FONCUSER () {
	echo -e "${CGREEN}Entrez le nom de l'utilisateur ruTorrent pour le volume lvm (\"0\" pour annuler) :${CEND}"
	read -r USER
	if [ "$USER" = "0" ] ; then
		return 1
	fi
	if ! [ -z "$1" ] ; then
		RE='^[a-z][-a-z0-9]*$'
		if ! [[ $USER =~ $RE ]] ; then
			echo -e "${CRED}Ce nom d'utilisateur n'est pas valide (^[a-z][-a-z0-9]*$)${CEND}"
			return 1
		fi
		if [ -L "$DEV"/"$VG"-"$USER" ] ; then
			echo -e "${CRED}Ce nom d'utilisateur existe déjà${CEND}"
			return 1
		fi
	else
		if ! [ -L "$DEV"/"$VG"-"$USER" ] ; then
			echo -e "${CRED}Ce nom d'utilisateur n'existe pas${CEND}"
			return 1
		fi
	fi
	return 0
}

FONCTAILLE () {
	echo -e "${CGREEN}Entrez la taille (en Go) souhaitée pour ce volume (entier naturel - \"0\" pour annuler) :${CEND}"
	read -r GO
	if [ "$GO" = "0" ] ; then
		return 1
	fi
	RE='^[0-9]+$'
	if [[ $GO =~ $RE ]] ; then
		TAILLE=$(echo "$GO * 1000 * 1000 * 1000" | bc)
	else
		echo "" ; echo -e "${CRED}Ceci n'est pas une valeur valide${CEND}"
		return 1
	fi
	return 0
}

FONCREDUC () {
	echo -e "${CYELLOW}Vous allez réduire la taille du volume${CEND}"
	echo -e "${CYELLOW}Le home de l'utilisateur sera démonté puis remonté${CEND}"
	echo -e "${CYELLOW}Voulez-vous lancer le redimensionnement ? (o/N)${CEND}"
	read -r R
	if [ R = "o" ] || [ R = "O" ] ; then
		fuser -mk /home/"$USER"
		umount --verbose /home/"$USER"
		e2fsck -f "$DEV"/"$VG"-"$USER"
		echo "" ; FONCREDIS
	else
		echo -e "${CBLUE}Le volume n'a pas été redimensionné${CEND}"
	fi
}

FONCAUGME () {
	echo -e "Vous allez augmenter la taille du volume"
	echo -e "Voulez-vous lancer le redimensionnement ? (O/n)"
	read -r A
	if [ A = "o" ] || [ A = "O" ] || [[ -z "$A" ]] ; then
		echo "" ; FONCREDIS
	else
		echo -e "${CBLUE}Le volume n'a pas été redimensionné${CEND}"
	fi
}

FONCREDIS () {
	lvresize -r -L "$TAILLE"B "$DEV"/"$VG"-"$USER"
	if [ $? -ge 2 ] ; then
		echo "" ; echo -e "${CRED}Une erreur rend l'opération impossible${CEND}" ; echo ""
		exit
	fi
	echo "" ; df -h /home/"$USER"
	echo "" ; FONCFREE
}

FONCVG () {
	TESTVG=$(lvm vgscan | sed '1d' | cut -d '"' -f2)
	if [ "$TESTVG" = "" ]; then
		VG="$VGNAME"
	else
		VG="$TESTVG"
	fi
}

FONCFREE () {
	FREE=$(vgdisplay --units G "$VG" | grep -w Free)
	echo -e "${CBLUE}Place disponible${CEND} ${CRED}(en Go)${CEND}\n${CYELLOW}$FREE${CEND}"
}

FONCOCCUP () {
	OCCUP=$(lvdisplay --units G "$DEV"/"$VG"-"$USER" | grep -w Size)
	echo -e "${CBLUE}Place occupé par l'utilisateur${CEND} ${CRED}(en Go)${CEND}\n${CYELLOW}$OCCUP${CEND}"
}

clear
echo -e "${CBLUE}                           Installation & Gestion LVM${CEND}"
echo -e "${CBLUE}
                                      |          |_)         _|
            __ \`__ \   _ \  __ \   _\` |  _ \  _\` | |  _ \   |    __|
            |   |   | (   | |   | (   |  __/ (   | |  __/   __| |
           _|  _|  _|\___/ _|  _|\__,_|\___|\__,_|_|\___|_)_|  _|
${CEND}"

while :; do
echo ""
echo -e "${CGREEN}Choisissez une option${CEND}"
echo ""
echo -e "${CYELLOW} 1 ${CEND} Installation LVM"
echo -e "${CYELLOW} 2 ${CEND} Rapport LVM"
echo -e "${CYELLOW} 3 ${CEND} Conversion Go en GiB"
echo ""
echo -e "${CYELLOW} 4 ${CEND} Ajout d'un volume utilisateur"
echo -e "${CYELLOW} 5 ${CEND} Augmentation ou réduction d'un volume utilisateur"
echo -e "${CYELLOW} 6 ${CEND} Suppression complète d'un volume utilisateur"
echo ""
echo -e "${CYELLOW} 0 ${CEND} Sortir..."
echo ""
echo -n -e "${CGREEN}Entrez votre choix :${CEND} "
read -r OPTION

case $OPTION in

	1)
		# Installation LVM
		TESTFS=$(grep -w /home "$FSTAB" | awk '{print $2}' | grep '^.....$')
		if [ "$TESTFS" = "" ] ; then
			TESTFS="/"
			echo -e "${CRED}Pas de partition /home disponible${CEND}"
			exit
		fi
		TEST=$(grep -w "$TESTFS" "$FSTAB" | awk '{print $1}' | grep -o / | wc -l)
		FSX=$(grep -w "$TESTFS" "$FSTAB" | awk '{print $1}' | awk -F/ '{print $NF}')
		if [ "$TEST" -eq "3" ] ; then
			FSX="md"$FSX
		fi
		sed -i "s/use_lvmetad = 0/use_lvmetad = 1/g" /etc/lvm/lvm.conf
		if vgdisplay | grep -q "$VGNAME" ; then
			echo "" ; echo -e "${CYELLOW}LVM est déjà installé${CEND}"
		else
			umount --verbose "$TESTFS"
			sed -i "/$FSX/d" "$FSTAB"
			pvcreate /dev/"$FSX"
			vgcreate "$VGNAME" /dev/"$FSX"
			echo "" ; vgdisplay --units G "$VGNAME"
		fi
	;;

	2)
		# Rapport LVM
		if vgdisplay | grep -q "$VGNAME" ; then
			echo "" ; echo -e "${CYELLOW}Attributs de groupes de volumes${CEND}" ; vgdisplay --unit G
			echo "" ; echo -e "${CYELLOW}Informations sur les volumes physiques${CEND}" ; pvs --units G
			echo "" ; echo -e "${CYELLOW}Information sur les groupes de volumes${CEND}" ; vgs --units G
			echo "" ; echo -e "${CYELLOW}Informations sur les volumes logiques${CEND}" ; lvs --units G
			echo -e "${CBLUE}Toutes les tailles sont données en${CEND} ${CRED}Go${CEND}"
		else
			echo "" ; echo -e "${CYELLOW}LVM n'a pas été installé${CEND}"
		fi
	;;

	3)
		# Conversion
		echo "" ; echo -e "${CBLUE}Entrez la taille en${CEND} GiB ${CBLUE}pour la convertir en ${CYELLOW}Go${CEND} (\"0\" pour annuler)${CEND} :"
		read -r CONV
		if ! [ "$CONV" = "0" ] ; then
			RE='^[0-9]+([,\.][0-9]+)?$'
			if [[ $CONV =~ $RE ]] ; then
				CONV=$(echo "$CONV" | sed "s/\,/./")
				TCONVGIB=$(echo "$CONV * 1.074" | bc)
				ETCONVGIB=${TCONVGIB%.*}
				CONVGIB=$(echo "$ETCONVGIB + 1" | bc)
				echo "" ; echo -e "$CONV GiB = ${CYELLOW}$CONVGIB Go${CEND}"
			else
				echo "" ; echo -e "${CRED}Ceci n'est pas une valeur valide${CEND}"
			fi
		fi
	;;

	4)
		# Ajout volume utilisateur
		FONCVG
		echo ""
		if FONCUSER "NewUser" ; then
			echo "" ; FONCFREE
			if FONCTAILLE ; then
				lvcreate -L "$TAILLE"B -n "$USER" "$VG"
				mkfs.ext4 "$DEV"/"$VG"-"$USER"
				mkdir -p /home/"$USER"
				mount "$DEV"/"$VG"-"$USER" /home/"$USER"
				echo "$DEV/$VG-$USER /home/$USER ext4 defaults 0 2" >> "$FSTAB"
				tune2fs -m 0 "$DEV"/"$VG"-"$USER"
				mount -o remount /home/"$USER"
				echo "" ; df -h /home/"$USER"
				echo "" ; FONCFREE
			fi
		fi
	;;

	5)
		# Augmentation ou reduction de l'espace disque
		FONCVG
		echo ""
		if FONCUSER ; then
			echo "" ; FONCFREE
			echo "" ; FONCOCCUP
			if FONCTAILLE ; then
				CGTAILLE=$(lvdisplay --units G "$DEV"/"$VG"-"$USER" | grep -w Size | awk '{print $(NF-1)}')
				TCBTAILLE=$(echo "$CGTAILLE * 1000 * 1000 * 1000" | bc)
				CBTAILLE=$(printf %.0f $TCBTAILLE)
				if [ "$TAILLE" -eq "$CBTAILLE" ] ; then
					echo "" ; echo -e "${CBLUE}La taille du volume est déjà configurée à cette valeur${CEND}"
					echo -e "${CBLUE}Le volume n'a pas besoin d'être redimensionné${CEND}"
				else
					if [ "$TAILLE" -lt "$CBTAILLE" ] ; then
						echo "" ; FONCREDUC
					else
						echo "" ; FONCAUGME
					fi
				fi
			fi
		fi
	;;

	6)
		# Suppression d'un volume utilisateur
		FONCVG
		echo ""
		if FONCUSER ; then
			fuser -mk /home/"$USER"
			umount --verbose /home/"$USER"
			lvremove /dev/"$VG"/"$USER"
			sed -i "/$VG-$USER/d" "$FSTAB"
			rm -R /home/"$USER"
			echo "" ; FONCFREE
		fi
	;;

	0)
		# Sortie
		echo "" ; break
	;;

	*)
		# Invalide
		echo "" ; echo -e "${CRED}Choix invalide${CEND}"
	;;

esac
done
