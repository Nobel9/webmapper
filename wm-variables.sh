#!/bin/bash

## Prüft über Auslesen der Variable $EUID ob Skript mit Admin-Rechten ausgeführt wird
## Falls nicht($EUID!=0): Gebe Nutzerhinweis aus und beende den Prozess
function check_for_sudo {
	[[ "$EUID" -ne 0 ]] && echo "Fehler: Bitte Starten sie das Skript mit dem Befehl: sudo bash wm-install.sh" && exit
}

## Prüft über Auslesen der Variable $control_bool ob die Installation forgesetzt werden soll
## Falls nicht ($control_bool=False): Gebe Nutzerhinweis und beende den Prozess
function wm_exit_check {
	[[ $control_bool == False ]] && echo "Die Installation wird abgebrochen." && exit
}

## Fügt einer Datei einen String nach einer bestimmten Zeichenfolge an
## wm_addline_aftermatch $match $new $file fügt Zeile $new nach der Zeichenfole $match in die Datei $file ein
function wm_addline_aftermatch {
	sudo sed -i "/$2/a$1" "$3"
}

## Hängt einer Datei eine Zeile an
## addline $file $string hängt die Zeichenfolge $string der Datei $file an
function addline {
	sudo echo "$2" >> "$1"
}

## Prüft eine Zeichenfolge ob ein bestimmtes Zeichen enthalten ist
## wm_checkchar $char $string prüft ob das Zeichen $char in der Zeichenfolge $string enthalten ist
## Falls nein: Die Variable controol_bool wird auf False gesetzt
function wm_checkchar {

	## Control-Boolean der auf False springt wenn eine Bedingung nicht erfüllt ist
	control_bool=True

	## Prüfe ob der zu suchende String nur ein Zeichen enthält, falls nicht: Setze Control-Boolean auf False
	[[ ${#1} != 1 ]] && control_bool=False
	
	## Prüfe ob das gesuchte Zeichen im String enthalten ist, falls nicht. Setze Control-Boolean auf False
	[[ $2 != *"$1"* ]] && control_bool=False
}

## Stellt eine Frage wiederholt bis gültige Antwort (Ein Zeichen) gegeben wurde
## wm_checkintanswer $question $allowedChars stellt Frage $question bis Antwort (Ein Zeichen) in String $allowedChars enhalten ist
function wm_checkintanswer {

	## Stelle Frage und Speichere Antwort in $intanswer
	read -p "$1" intanswer
		
	## Prüfe ob Eingabe gültig ist (Ein Zeichen und in $2 enthalten), Antwort wird in control_bool gespeichert
	wm_checkchar "$intanswer" "$2"

	## Starte die Funktion neu falls Eingabe ungültig ist
	[[ $control_bool == False ]] && echo "Sie haben eine ungültige Eingabe getätigt. Bitte geben sie eins der folgenden Zeichen ein:" && echo "$2" && wm_checkintanswer "$1" "$2" && return

	## Speichere erfolreiche Nutzereingabe
	answer=$intanswer
}

## Stellt eine Frage wiederholt, bis die Antwort eine Mindestlänge hat, nur aus erlaubten Zeichen besteht und alle benötigten Zeichen enthalten sind
## wm_checkstringanswer $question $allowedChars $visibility_bool $min_length $default_value $neededChars ...
## ...stellt Frage $question bis die Antwort ... 
## ...nur aus Zeichen besteht die in $allowedChars enthalten sind, ...
## ...eine Mindestlänge von $min_length hat und
## ...alle Zeichen aus $neededChars in der Antwort enthalten sind
## Ist $visibility_bool=False wird die Eingabe nicht angezeit (Sinnvoll für Passwörter)
## $default_value defininiert die Zeichenfolge die dem Nutzer vorgeschlagen wird
function wm_checkstringanswer {

        ## Nutzerdialog, Verdeckt (-s) und ohne default Value $4 wenn visibleBoolean $3=False
        [[ "$3" != False ]] && read -p "$1" -i "$5" -e stringanswer || read -s -p "$1" stringanswer && echo
		
		## Setze control_bool auf True, Springt auf False wenn eine Bedingung nicht erfüllt ist
		control_bool=True
		
		## Bestimmt Länge der Antwort und überprüft ob die geforderte Mindestlänge erfüllt ist, falls nicht erfüllt -> Control Bool springt auf False
		stringlen="${#stringanswer}"
		minlen="$4"
		difflen="$((stringlen - minlen))"
		[[ "$4" != "" ]] && [[ $difflen < 0 ]] && echo "Ihre Eingabe muss mindestens $4 Zeichen enthalten." && control_bool=False

        ## Überprüfe ob das Zeichen$ in Eingabe, wird durch UbuntuVariablen-Bezeichnung erlaubt, Beispiel: pw=foo$x -> pw=foo' ', falls $ in Antwort -> Control Bool springt auf False
        [[ $control_bool != False ]] && [[ $stringanswer == *"$"* ]] && echo "Bitte benutzen Sie keine Dollar-Zeichen in ihrer Eingabe." && control_bool=False

        ## Prüfe für jedes Zeichen aus $stringanswer ob es zu den erlaubten Zeichen gehört, falls nicht springt durch wm_checkchar der Control-Boolean auf False
        if [[ $control_bool != False ]]; then
			for (( i=0; i<${#stringanswer}; i++ )); do
					wm_checkchar "${stringanswer:$i:1}" "$2"
					[[ $control_bool == False ]] && echo "Ihre Eingabe enthält ein nicht unterstütztes Zeichen. Unterstützt werden alle Zeichen aus:" && echo "$2" && break
			done
		fi
		
        ## Prüfe für jedes geforderte Zeichen, ob es in $stringanswer enthalten ist, falls nicht springt durch wm_checkchar der Control-Boolean auf False
        if [[ $control_bool != False ]]; then
			if [[ "$6" != "" ]]; then
					for (( i=0; i<${#6}; i++ )); do
							wm_checkchar "${6:$i:1}" "$stringanswer"
							[[ $control_bool == False ]] && echo "Ihrer Eingabe fehlt ein benötigtes Zeichen. Benötigt werden alle Zeichen aus:" && echo "$6" && break
					done
			fi
		fi

        ## Starte die Funktion neu falls mindestens eine Bedingung nicht erfüllt ist eine Rückmeldung an den Nutzer
        [[ $control_bool == False ]] && wm_checkstringanswer "$1" "$2" "$3" "$4" "$5" "$6" && return

        ## Speichere erfolreiche Nutzereingabe und speichere zusätzlich die letzte Nutzereingabe in neue Variable ...
		## ...um Überprüfung auf Gleicheit zweier Strings (zB für die Festlegung von Passwörtern) zu ermöglichen
        answer_1=$answer
        answer=$stringanswer
}

## Prüft ob Eingabe eine Zeichenfolge nur aus erlaubten Zeichen, Falls nicht setze control_bool auf False
## wm_checkstring $string $allowedChars prüft für jeden Zeichen aus $string ob es in $allowedChars enthalten ist.
function wm_checkstring {

	## Prüfe für jedes Zeichen aus $1 ob es in $2 enthalten ist, falls nicht Setze Control Bool auf False    
	for (( i=0; i<${#1}; i++ )); do
		wm_checkchar "${1:$i:1}" "$2"
		[[ $control_bool == False ]] && break
	done

	## Überprüfe ob $ in Eingabe, wird durch UbuntuVariablen-Bezeichnung erlaubt, Beispiel: pw=foo$x -> pw=foo' '        
	[[ $1 == *"$"* ]] && control_bool=False

	## Gebe falls mindestens eine Bedingung nicht erfüllt ist eine Rückmeldung an den Nutzer
	[[ $control_bool == False ]] && echo Ihre Eingabe enthält ein nicht unterstütztes Zeichen. && echo Unterstützt werden a-z, A-Z, 0-9 und die Zeichen: . , ! ?
}

############################################################################################################
#################################### Allgemeine Webmapper Funktionen #######################################
############################################################################################################

## Definiert nötige Variable für die Installation
function wm_variables_set {

	## PostgresPort
	mypgport=5432

	## Liest ausführenden Nutzer aus
	myuser=$SUDO_USER
	
	## Pfade zu Nutzerbildern, die in der Anwendung verwendet werden sollen
	myimgpath="/home/$myuser/img"
	mylogo=$myimgpath"/logo_60x60.png"
	myfooter=$myimgpath"/logo_35x110.png"
	myheader=$myimgpath"/header_1427x76.png"

	## Log Dateien für die Installation
	log_err="/home/$myuser/wm_err.log"
	log_out="/home/$myuser/wm_out.log"

	## Apache Config Dateien
	apache_conf="/etc/apache2/sites-available/000-default.conf"
	apache_conf_ssl="/etc/apache2/sites-available/000-default-le-ssl.conf"

	## PostgreSQL Config Dateienpfadteile
	pg_prepath="/etc/postgresql/"
	postgresql_conf_post="/main/postgresql.conf"
	pghba_conf_post="/main/pg_hba.conf"
	pgservice_conf="/etc/postgresql-common/pg_service.conf"

	## Erlaubte Zeichen bei Nutzereingabe
	charlist="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.,!?0123456789"
	charlist_db="abcdefghijklmnopqrstuvwxyz_0123456789"
	charlist_pwd="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.,!?0123456789"
	charlist_domain="abcdefghijklmnopqrstuvwxyz.0123456789-"
	charlist_email="abcdefghijklmnopqrstuvwxyz.@0123456789-"
	charlist_appname="abcdefghijklmnopqrstuvwxyz0123456789-_"
	
	## Default Values für Nutzerdialog
	default_appname="webmapper"
	default_domain=$default_appname".de"
	default_email="email@institution.de"

	## Fragestellungen zur Nutzerinteraktion
	question_db="Bitte geben Sie einen Namen für die Datenbank an: "
	question_pwd1="Bitte geben Sie ein Passwort für den Nutzer $myuser an: "
	question_pwd2="Bitte geben Sie das Passwort erneut ein: "
	question_domain="Bitte heben Sie den Namen ihrer Domain ohne www. ein (z.B. mydomain.com): "
	question_email="Bitte geben Sie Ihre Email ein. Diese wird nur verwendet um Sie darauf hinzuweisen falls die automatische Verlängerung des SSL-Zertifikats Probleme bereitet. Alternativ geben Sie bitte \"$default_email\" ein: "
	question_appname="Bitte geben Sie den Namen ihrer Anwendung z.B. 'webmapper' an (Nach der Installation werden Sie WebMapper unter www.domain/Anwendungsname erreichen können): "
	question_welcome="Wollen Sie die Installation jetzt starten (1=Installation starten, 2=Installation abbrechen)? "
	question_user_n="Wollen Sie mit den aufgeführten Einstellungen die Installation fortsetzen (1=Installation fortsetzen, 2=Einstellungen ändern, 3=Installation abbrechen)? "
	question_ssd="Haben Sie eine zusätzliche, freie und unpartitionierte Festplatte im System und wollen diese verwenden (1=Installieren mit neuer Festplatte, 2=Installieren ohne neue Festplatte)? "
}

## Funktion die Uhrzeit und Befehl in Logdateien schreibt um dort mehr Übersicht zu erhalten
## wm_log_prentry $befehl schreibt den Befehl und die Uhrzeit zu der er ausgeführt worden ist in die Log Dateien
function wm_log_prentry {

	## Baue Message aus Uhrzeit und Befehl zusammen
	message=$(date +"%T")" "$1
	
	## Gebe Message an Nutzer aus und speichere in Logdateien
	echo $message && sudo echo $message >> "$log_err" && sudo echo $message >> "$log_out"
}

############################################################################################################
############################################# Nutzerinfos ##################################################
############################################################################################################

## Bergrüßungfunktion, gibt Nutzer Informationen, fragt Nutzer ob die Installation gestartet werden soll
function wm_welcome {

	## Begrüßungstext
	echo "Der WebMapper-Installationsassistent startet..." 
	echo && echo "Für die Installation von WebMapper benötigen sie:" && echo "----Ubuntu 20.04. Pro LTS (als virtuelle Maschine z.B. bei Azure)" && echo "----Eine neue (frei, unpartitioniert, nicht gemountet) Festplatte am Ubuntu" && echo "----Eine freie Domain" && echo "----Ein paar Minuten Zeit" && echo

	## Nutzerdialog ob Installation gestartet werden lssoll
	wm_checkintanswer "$question_welcome" 12

	## Wertet Antwort aus und setzt control_bool je nach Antwort
	[[ $answer == 1 ]] && control_bool=True
	[[ $answer == 2 ]] && control_bool=False
	echo
}

## Funktion, die bei der Erarbeitung die zusätzliche Möglichkeit gibt, falls aufgrerufen die Installation zu beenden
function wm_stepstop {

	## Nutzerdialog ob Installation gestartet werden soll
	wm_checkintanswer "Weiter? [1/2]" 12

	## Wertet Antwort aus und setzt control_bool je nach Antwort
	[[ $answer == 1 ]] && control_bool=True
	[[ $answer == 2 ]] && control_bool=False
	
	## Beende gegebenfalls die Installation
	wm_exit_check
}

## Ausgabe am Ende des Nutzerdialogs
function wm_finished {
	echo && echo Die Installation ist abgeschlossen. && echo Ihr Nutzername für Ubuntu und PostgreSQL lautet: $myuser && echo Ihre PostgreSQL-Datenbank heißt: $mydb && echo Ihr Passwort für PostgreSQL lautet: $mypw 
	echo && echo "Weitere Schritte:" && echo "Legen Sie auf allen Computern von denen Sie mit QGIS auf die PostGIS-Datenbank zugreifen wollen eine Datei mit dem Namen pg_service.conf an und füllen Sie diese mit dem folgenden Inhalt:" && echo "$(sudo cat /etc/postgresql-common/pg_service.conf)"
	echo && echo "Legen Sie eine Neue Systemvariable an indem Sie die Eingabeaufforderung öffnen mit: WINDOWS + cmd + Enter und folgenden Befehl eingeben" && echo 'setx PGSERVICEFILE "Dateipfad\pg_service.conf"' && echo 'z.B.: setx PGSERVICEFILE "C:\Users\USERNAME\pg_service.conf"'
	echo && echo "Um sich aus QGIS auf die Datenbank zu verbinden reicht es nun den Namen des Services (siehe oben in eckige Klammern) anzugeben."
	echo && echo "Öffnen Sie Ihren Internetbrowser und öffnen Sie WebMapper unter:" && echo https://$mydomain oder https://www.$mydomain
}

############################################################################################################
######################################## Nutzerdefinition von Variablen ####################################
############################################################################################################

## Datenbanknamendialog
function wm_db_n {

	## Stelle Frage bis korrekte Antwort erhalten
	wm_checkstringanswer "$question_db" "$charlist_db" True 3 $myappname"_db"  

	## Speichere die erfolgreiche Nutzereingabe in Kleinbuchstaben
	mydb="$answer"
}

## Passworteingabedialog
function wm_pwd_n {

	## Stelle Frage bis korrekte Antwort erhalten, zweimal zur Bestätigung erste Antwort wird durch Funktion $answer_1 gespeichert
	wm_checkstringanswer "$question_pwd1" "$charlist_pwd" False 6
	wm_checkstringanswer "$question_pwd1" "$charlist_pwd" False 6

	## Überprüfe ob Eingaben übereinstimmen, wenn nicht starte neue Eingabe
	[[ "$answer" != "$answer_1" ]] && echo "Die Eingaben stimmen nicht überein. Versuchen Sie es erneut." && wm_pwd_n && return
        
	## Speichere die erfolgreiche Nutzereingabe
	mypw="$answer"
}

## Domaineingabedialog
function wm_domain_n {
	
	## Domaineingabedialog
	wm_checkstringanswer "$question_domain" "$charlist_domain" True 3 "$default_domain" "."
	
	## Speichere Erfolgreiche Nutzereingabe
	mydomain="$answer"
}

## Emaileingabedialog
function wm_email_n {

	## Emaileingabedialog
    wm_checkstringanswer "$question_email" "$charlist_email" True 5 "$default_email" "@."

	## Speichere Erfolgreiche Nutzereingabe
	myemail="$answer"
}

## Appnameeingebedialog
function wm_appname_n {

	## Appnameeigabedialog
	wm_checkstringanswer "$question_appname" "$charlist_appname" True 1 "$default_appname"
	
	## Speichere erfolgreiche Nutzereigabe
	myappname="$answer"
}

## Ermittelt freie, unpartitionierte Festplatten
function wm_disc_get {

	## Nutzerdialog ob Installation gestartet werden soll
	wm_checkintanswer "$question_ssd" 12

	if [[ $answer == 1 ]]; then

		## Liste der Festplatten und ihrer Partitionen
		disclist_name=$(sudo lsblk -o NAME | grep -i "sd")

		## Wähle freie Festplatten aus, Bedingungen: 3 Buchstaben, keine Partitionen
		## Speichere freie Festplatte in $disclist_free
		disclist_free=''
		for disc in $disclist_name; do
			[[ ${#disc} == 3 ]] && [[ $(grep -o $disc <<< *"$disclist_name"* | wc -l) == 1 ]] && disclist_free+=$disc" "
		done

		## Zähle freie Platten
		disccount=$(wc -w <<< "$disclist_free")

		## Werte Ergebnis aus, 1 freie Disc -> Starte, keine Freie Disc -> Breche ab, mehr als 1 freie disc, frage Nutzer welche genutzt werden soll
		control_bool=True
		[[ $disccount == 0 ]] && echo "Es ist keine freie Festplatte vorhanden." && mydisc=keine
		[[ $disccount == 1 ]] && mydisc=$disclist_free
		if [[ $disccount > 1 ]]; then

			## Nutzerinfos über Festplatten
			[[ $1 != noecho ]] && echo "Es ist mehr als eine freie Festplatte verfügbar. Sie sehen nun eine Übersicht aller Festplatten:" && sudo lsblk -o NAME,HCTL,SIZE,MOUNTPOINT | grep -i "sd"

			## Nutzereingabe
			echo "Bitte wählen Sie eine von: $disclist_free: "
			read answer

			## Prüfe Antwort auf Gültigkeit, ungültig -> neu Starten
			[[ ${#answer} != 3 ]] && echo "Ungültige Eingabe" && wm_disc_get noecho && return
			[[ $(grep -o $answer <<< *"$disclist_free"* | wc -l) != 1 ]] && echo "Ungültige Eingabe" && wm_disc_get noecho

			## Speichere Nutzereingabe
			mydisc=$answer
		fi
		
		## Speichere zu nutzende Festplatte
		mydisc=$(echo $mydisc | xargs)
	else

		## Speichere den string "keine" in $mydisc, wenn keine Festplatte gewünscht ist
		mydisc=keine 
	fi
	echo
	
}

## Masterfunktion der Benutzerinteraktion
function wm_user_n {

	## Lege Variablen mit Namen für Datenbank, Passwort, Domain und Mail an
	wm_appname_n && echo && wm_db_n && echo && wm_pwd_n && echo && wm_domain_n && echo && wm_email_n && echo && wm_disc_get && echo

	## Ausgabe zur Überprüfung der Eingaben; Frage Nutzer ob er mit den Angaben fortfahren fortfahren will
	echo WebMapper ist bereit zur Installation. && echo "Nutzername: $myuser" && echo "Appname: $myappname" && echo "Datenbank: $mydb" && echo "Domain: $mydomain" && echo "Email: $myemail" && echo "Neue Festplatte: $mydisc"
	wm_checkintanswer "$question_user_n" 123

	## Führe Aktion je nach Nutzereingabe aus; 1=Weiter, 2=Eingaben Ändern, 3=Beenden
	[[ $answer == 1 ]] && control_bool=True
	[[ $answer == 2 ]] && echo && wm_user_n && return
	[[ $answer == 3 ]] && control_bool=False
}

############################################################################################################
##################################### Festplatten und Mounting #############################################
############################################################################################################

## Partitioniert die Festplatte die in der Variable $mydisc gespeichert ist
function wm_disc_part {

	## Partitioniere die Festplatte
	sudo parted /dev/$mydisc --script mklabel gpt mkpart xfspart xfs 0% 100% 2>>$log_err 1>>$log_out
	sudo partprobe /dev/${mydisc} 2>>$log_err 1>>$log_out
	sudo mkfs.ext4 /dev/${mydisc}1 2>>$log_err 1>>$log_out
	echo
	
}

## Hängt die Festplatte $mydisc an der Stelle /home/$myuser/$myappname in das Dateisystem ein
function wm_disc_mount {

	## Gebe $myuser alle Rechte auf dem Verzeichnis
	sudo chown $myuser:$myuser /home/$myuser/$myappname
	
	## Hänge Festplatte ein
	sudo mount /dev/${mydisc}"1" /home/$myuser/$myappname
	echo

}

## Ermittel die eindeutige Kennung (UUID) der Festplatte $mydisc
function wm_get_uuid {

	## Gebe Festplatten UUIDs aus
	uuid=$(sudo blkid)

	## Extrahiere UUID der gewünschten Platte
    delimiter="/dev/${mydisc}1: UUID="
	string=$uuid$delimiter
	myarray=()
	while [[ $string ]]; do
		myarray+=( "${string%%"$delimiter"*}" )
		string=${string#*"$delimiter"}
	done
	uuid=(${myarray[1]})
	
	## Entferne Anführungszeich am Anfang und am Ende
	uuid=${uuid%\"} 
	uuid=${uuid#\"}

	## Speicherer UUID
	myuuid=$uuid
	echo

}

## Sorgt for dauerhaftes Einhängen der Festplatte $mydisc unter der Verwendung der eindeutigen Kennung $myuuid
function wm_stay_mounted {
	
	## Definiert Zeile die für Dauerhaftes Mounting sorft
	line="UUID=$myuuid /home/$myuser/$myappname ext4 defaults,nofail 1 2    # Diese Zeile wurde durch webmapper hinzugefügt"
	
	## Füge die definierte Zeile in die Datei /etc/fstab ein 
	sudo echo "$line" >> /etc/fstab
	echo
}

## Masterfunktion für das Identifizieren und Einhängen der Festplatte
function wm_disc_mount_master {
	
	## Erstelle nötigen Ordner
	sudo mkdir /home/$myuser/$myappname

	## Falls $mydisc definiert ist
	if [ $mydisc != "keine" ]; then
	
		wm_log_preentry "Einhängung der zusätzlichen Festplatte"
	
		## Partitioniere die Festplatte
		wm_disc_part
		
		## Hänge die Festplatte ein
		wm_disc_mount
		
		## Ermittle die eindeutige Kennung der Festplatte
		wm_get_uuid
		
		## Sorge für ein dauerhaftes Einhängen der Festplatte
		wm_stay_mounted
	fi
	
	## Gebe dem Nutzer alle Rechte auf der Festplatte (Könnten durch sudo mkdir bei root liegen)
	sudo chown $myuser:$myuser /home/$myuser/$myappname
}

############################################################################################################
##################################### QGIS Server, Apache und Co. ##########################################
############################################################################################################

## Installiert Apache Webserver, QGIS Server und weitere benötigte Pakete
function wm_qgisserver_apache {

	wm_log_preentry "Installiere Apache, QGIS Server, PHP und weitere Pakete"
	
	## Dieses Paket muss ganz am Anfang installiert werden, da sonst ppa:ondrej/php nicht hinzugefügt werden kann
	sudo apt-get install software-properties-common -y 2>>$log_err 1>>$log_out
	
	## Hinzufügen des Verzeichnisses für neuere PHP-Pakete
	sudo add-apt-repository ppa:ondrej/php -y 2>>$log_err 1>>$log_out
	
	## Update das Paketverzeichnos
	sudo apt update 2>>$log_err 1>>$log_out && echo
	
	## Installiere weitere benötiget Pakete
	sudo apt install xauth -y 2>>$log_err 1>>$log_out
	sudo apt install htop -y 2>>$log_err 1>>$log_out
	sudo apt install curl -y 2>>$log_err 1>>$log_out

	## Installiere Apache
	sudo apt-get install apache2 -y 2>>$log_err 1>>$log_out
	
	## Installiere zusätzliche Apache und PHP Module
	sudo apt install libapache2-mod-fcgid -y 2>>$log_err 1>>$log_out
	sudo apt install libapache2-mod-php7.3 -y 2>>$log_err 1>>$log_out
	sudo apt install php7.3-cgi -y 2>>$log_err 1>>$log_out
	sudo apt install php7.3-gd -y 2>>$log_err 1>>$log_out
	sudo apt-get install php7.3-sqlite -y 2>>$log_err 1>>$log_out
	sudo apt install php7.3-curl -y 2>>$log_err 1>>$log_out
	sudo apt install php7.3-xmlrpc -y 2>>$log_err 1>>$log_out
	sudo apt install php7.3-xml -y 2>>$log_err 1>>$log_out
	sudo apt install python3-simplejson -y 2>>$log_err 1>>$log_out

	## Installiere unzip, wird für das Entpacken vom Lizmap Archiv aus Github benötigt
	sudo apt install unzip -y 2>>$log_err 1>>$log_out
	
	## Installiere QGIS-Server
	echo "Installiere QGIS Server"
	sudo apt install qgis-server -y 2>>$log_err 1>>$log_out
}

## Installiert und aktiviert das QGIS-Server-Plugin wfsOutputExtension
function wm_wfsoutputextension {

	wm_log_preentry "Installiere wfsOutputExtension"
	
	## Variable
	wfsoutput_version="1.7.0"
	wfsoutput_gitpath="https://github.com/3liz/qgis-wfsOutputExtension/archive/refs/tags/$wfsoutput_version.zip"
	wfsoutput_zippath="/home/$myuser/$wfsoutput_version.zip"
	wfsoutput_ubupath="/home/$myuser/qgis-wfsOutputExtension-$wfsoutput_version"
	qgisserver_plugins_path="/usr/lib/qgis/plugins"
	pluginpath_var="\\\n\tFcgidInitialEnv QGIS_PLUGINPATH \"$qgisserver_plugins_path/\""
	pluginpath_match="20"
	fcgid_path="/etc/apache2/mods-available/fcgid.conf"
	
	## Lade Archiv von GitHub herunter
	sudo wget $wfsoutput_gitpath -P /home/$myuser/ 2>>$log_err 1>>$log_out
	
	## Entpacke das Archiv
	sudo unzip $wfsoutput_zippath -d /home/$myuser/ 2>>$log_err 1>>$log_out
	
	## Entferne das Archiv
	sudo rm $wfsoutput_zippath
	
	## Verschiebe die benötigten entpackten Dateien
	sudo mv $wfsoutput_ubupath/wfsOutputExtension/ $qgisserver_plugins_path/
	
	## Lösche nichr benötigte Ordner und Dateien
	sudo rm -r $wfsoutput_ubupath
	
	## Füge Konfiguration der Datei fcgid.conf hinzu
	wm_addline_aftermatch "$pluginpath_var" "$pluginpath_match" "$fcgid_path"
	#sudo sed -i "/$pluginpath_match/a$pluginpath_var" "$fcgid_path"
	
	## Starte den Apache Webserver neu
	sudo service apache2 restart
}

############################################################################################################
############################################# Lizmap #######################################################
############################################################################################################

## Installiert und Konfiguriert den Web-Map-Client Lizmap
function wm_lizmap {

	wm_log_prentry "Installiere und konfiguriere Lizmap"

	# Variable
	lizmap_version=3.5.3
	lizmap_gitpath="https://github.com/3liz/lizmap-web-client/releases/download/$lizmap_version/lizmap-web-client-$lizmap_version.zip"
	lizmap_ubupath="/var/www/lizmap-web-client-$lizmap_version"
	lizmap_configdir=$lizmap_ubupath"/lizmap/var/config"	
	lizmap_imagepath=$lizmap_ubupath"/lizmap/www/themes/default/css/img"
	lizmap_logo=$lizmap_imagepath"/logo.png"
	lizmap_footer=$lizmap_imagepath"/logo_footer.png"
	lizmap_header=$lizmap_imagepath"/header_1427x76.png"
	match="*:80>"
	configs="\\\n\tScriptAlias /cgi-bin/ /usr/lib/cgi-bin/\n\t\t<Directory \"/usr/lib/cgi-bin/\">\n\t\tOptions ExecCGI FollowSymLinks\n\t\tRequire all granted\n\t\tAddHandler fcgid-script .fcgi\n\t</Directory>"
	
	## Lade das Lizmap Archiv von Github herunter
	sudo wget $lizmap_gitpath -P /var/www/ 2>>$log_err 1>>$log_out
	
	## Entpache das Archiv
	sudo unzip $lizmap_ubupath.zip -d /var/www/ 2>>$log_err 1>>$log_out
	
	## Erstelle eine Verlinkung auf einen neuen Ordner unter /var/www/html/$myappname
	sudo ln -s $lizmap_ubupath/lizmap/www/ /var/www/html/$myappname 2>>$log_err 1>>$log_out
	
	## Aktiviere Fast CGI
	sudo a2enmod fcgid 2>>$log_err 1>>$log_out
	sudo a2enconf serve-cgi-bin 2>>$log_err 1>>$log_out
	
	## Füge Konfiguration in die Apache-Konfigurationsdatei 000-default.con
	wm_addline_aftermatch "$configs" "$match" $apache_conf
	#sudo sed -i "/$match/a$configs" "$apache_conf"
	
	## Vergebe vor Installation alle nötigen Rechte an Nutzer www-data, wird später nochmal ausgeführt, da hier manchmal ein Fehler auftritt
	sudo $lizmap_ubupath/lizmap/install/set_rights.sh www-data www-data
	
	## Erstelle nötige Konfigurationsdateien durch Kopien
	sudo cp $lizmap_configdir/lizmapConfig.ini.php.dist $lizmap_configdir/lizmapConfig.ini.php
	sudo cp $lizmap_configdir/localconfig.ini.php.dist $lizmap_configdir/localconfig.ini.php
	sudo cp $lizmap_configdir/profiles.ini.php.dist $lizmap_configdir/profiles.ini.php

	## Installiere Lizmap
	sudo php $lizmap_ubupath/lizmap/install/installer.php 2>>$log_err 1>>$log_out

	## Gebe dem Webserver nötige Rechte für Lizmao und den Ordne /home/$myuser
	sudo $lizmap_ubupath/lizmap/install/set_rights.sh www-data www-data
	sudo chown $myuser:www-data /home/$myuser/
	
	## Starte Apache neu
	sudo service apache2 restart 2>>$log_err 1>>$log_out
}

## Tauscht Lizmapdefaultbilder gegen Nutzerbilder aus dem Ordner /home/$myuser/img/ aus
function wm_lizmap_design {
	sudo cp $mylogo $lizmap_logo
	sudo cp $myfooter $lizmap_footer
	sudo cp $myheader $lizmap_header
}

## Fügt wm-projects.py einen Funktionsaufruf mit den Parameter $myuser und $myappname an und ändert Maximal erlaubte Dateigröße für Medienupload
function wm_lizmap_downloadscript {

	## Fügt Nutzername und Anwendungsname dem Pythonscript hinzu, dass die Download.js Dateien erstellt und den upload Folder regelt
	sudo echo "" >> /home/$myuser/wm-projects.py && sudo echo "configure_wm_projects('$myuser', '$myappname')" >> /home/$myuser/wm-projects.py
	
	## PHP Config, erlaubt größere Datenmenge beim Upload
	sudo sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 20M/' /etc/php/7.3/apache2/php.ini
}

############################################################################################################
##################################### PostgreSQL und PostGIS ###############################################
############################################################################################################

## Installiert und Konfiguriert PostgreSQL und die Erweiterung PostGIS
function wm_postgisdb {

	wm_log_prentry "Installiere und konfiguriere PostgreSQL"
		
	# Variable
	pg_prepath="/etc/postgresql/"
	postgresql_conf_post="/main/postgresql.conf"
	pghba_conf_post="/main/pg_hba.conf"
	pgservice_conf="/etc/postgresql-common/pg_service.conf"
	mypgport=5432
		
	## Installiere die nötigen Pakete
	sudo apt-get install postgresql -y 2>>$log_err 1>>$log_out
	sudo apt-get install postgresql-contrib -y 2>>$log_err 1>>$log_out
	sudo apt-get install postgis -y 2>>$log_err 1>>$log_out
	sudo apt-get install php7.3-pgsql -y 2>>$log_err 1>>$log_out
		
	# Variable II: Lese Postgres Version aus (geht erst nach Installtion)
	pg_version=$(ls /etc/postgresql)
	postgresql_conf=$pg_prepath$pg_version$postgresql_conf_post
	pghba_conf=$pg_prepath$pg_version$pghba_conf_post
	
	## Wechsele den Ordner um keine Berechtigungsprobleme zu bekommen
	cd /

	## Erstellt Cluster, Funktioniert leider nicht gleichzeitig mit den Projekten in /home/$myuser/$myappname
	## Hier könnte man eine zweite Festplatte für nutzen
	## Zunächst wird Postgres ohne neues Cluster auf der Hauptfestplatte verwendet.
	#sudo mkdir /home/$myuser/$myappname/postgresql
	#sudo service postgresql stop
	#sudo pg_dropcluster --stop $pg_version main
	#sudo chown postgres:postgres /home/$myuser/$myappname/postgresql
	#sudo pg_createcluster $pg_version main -d /home/$myuser/$myappname/postgresql --user $myuser	

	## Erstelle Datenbank, installiere Postgis erweiterung auf der DB
	sudo -u postgres createuser $myuser 2>>$log_err 1>>$log_out
	sudo -u postgres psql -c "alter user $myuser with password '${mypw}'" 2>>$log_err 1>>$log_out
	sudo -u postgres createdb $mydb -O $myuser 2>>$log_err 1>>$log_out
	sudo -u postgres psql -d $mydb -c "CREATE EXTENSION postgis;" 2>>$log_err 1>>$log_out

	## Starte Postgres bei jedem Systemstart mit
	sudo systemctl enable postgresql 2>>$log_err 1>>$log_out
	
	## Netzwerkeinstellungen
	addline $postgresql_conf "listen_addresses = '*'    # Diese Zeile wurde durch webmapper hinzugefügt" 
	addline $pghba_conf "host    all             all             0.0.0.0/0               md5    # Diese Zeile wurde durch webmapper hinzugefügt" 
	
	# Legt PGSERVICE File an
	addline $pgservice_conf "[${mydb}_service]"
	addline $pgservice_conf "host=$mydomain"
	addline $pgservice_conf "port=$mypgport"
	addline $pgservice_conf "user=$myuser"
	addline $pgservice_conf "password=$mypw"
	addline $pgservice_conf "dbname=$mydb"

	## Starte Postgres neu
	sudo systemctl restart postgresql 2>>$log_err 1>>$log_out
	
	## Wechsele wieder ins Nutzerverzechnis
	cd /home/$myuser
}

############################################################################################################
##################################### TLS/SSL ##############################################################
############################################################################################################

#### Installiert SSL Zertifikat
function wm_ssl_install {
	
	wm_log_prentry "Installiere SSL Zertifikat"
	
	## Variable
	apache_conf_ssl="/etc/apache2/sites-available/000-default-le-ssl.conf"

	## Installiert benötigte Pakete
	sudo apt install certbot -y 2>>$log_err 1>>$log_out
	sudo apt install python3-certbot-apache -y 2>>$log_err 1>>$log_out

	## Schreibe Domain in Apache-Konfigurationsdatei
    match="*:80>"
    aliases="\\\n\tServerAlias $mydomain\n\tServerAlias www.$mydomain"
    wm_addline_aftermatch "$aliases" "$match" $apache_conf
	
	## Generiere und installiere Zertifikat (zwei Unterschiedliche Arten je nachdem ob eine Mail-Adresse angegeben wurde oder nicht)
	[[ "$myemail" == "$default_email" ]] && sudo certbot --apache --non-interactive --register-unsafely-without-email --agree-tos -d ${mydomain} -d www.${mydomain} --redirect || sudo certbot --apache --non-interactive -m ${myemail} --agree-tos --no-eff-email -d ${mydomain} -d www.${mydomain} --redirect 2>>$log_err 1>>$log_out

	## Füge Redirection in SSL Config ein
	match="\/var\/www\/html"
	redirection="\\\n\tRedirectMatch Permanent \"^(/(?\!$myappname/).*)\" https://$mydomain/$myappname\$1"
	wm_addline_aftermatch "$redirection" "$match" $apache_conf_ssl
        
	## Starte Apache neu
	sudo service apache2 restart
}
