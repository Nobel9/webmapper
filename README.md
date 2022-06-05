# Webmapper
## Die Installationsroutine für ein Web-Mapping-Portal mit Ubuntu, Apache, QGIS Server, PostgreSQL und Lizmap

Für die Installation der Web-Map-Anwendung werden die folgenden Komponenten vorausgesetzt:

	- Ubuntu 22.04 Pro LTS (als virtuelle Maschine, im Idealfall neu und leer)	
	
	- Eine leere, unpartitionierte Festplatte im System (Empfohlen)
	
	- Eine freie Domain, deren DNS Eintrag die IP-Adresse des Ubuntu enthält
	
Folgende Anwendungen und Pakete, zusätzlich der durch diese Pakete selbstständig installierten Software, werden im Rahmen der Installationsroutine installiert:

	- apache2
	
	- certbot
	
	- curl
	
	- htop
	
	- libapache2-mod-fcgid
	
	- libapache2-mod-php7.3
	
	- lizmap (Web-Map-Client; von GitHub)
	
	- php7.3-cgi
	
	- php7.3-curl
	
	- php7.3-gd
	
	- php7.3-pgsql
	
	- php7.3-sqlite
	
	- php7.3-xml
	
	- php7.3-xmlrpc
	
	- postgis
	
	- postgresql
	
	- postgresql-contrib
	
	- python3-certbot
	
	- python3-simplejson
	
	- qgis-server
	
	- software-properties-common
	
	- unzip
	
	- wfsOutputExtension (QGIS Server Erweiterung; von GitHub)
	
	- xauth

### Installationsanleitung

#### Herunterladen der nötigen Dateien
Um die Web-Map-Anwendung zu installieren, müssen die Webmapper-Dateien aus GitHub heruntergeladen und gegebenenfalls per SSH (ssh username@ip) in das Homeverzeichnisses des Maschinenusers (/home/USERNAME) verschoben werden. Es müssen die folgenden Dateien und Ordner vorhanden sein:

	- wm-install.sh
	
	- wm-projects.py
	
	- wm-variables.sh
	
	- img/ (Ordner; Enthält das Anwendungslogo und weitere Bilder, bis auf footer können alle diese Bilder im Browser bearbeitet werden)

#### (Optional) Anpassen der Anwendungslogos
Um das Logo, das Banner und den Footer automatisch bei der Installation durch eigene Bilder zu ersetzen (Der Footer kann nicht im Browser nachträglich definiert werden), ersetzen Sie die Bilder im Ordner /home/USERNAME/img durch ihre eigenen. Beachten Sie bitte, dass Ihre Bilder, dieselben Dateinamen besitzen, wie die zu ersetzenden Bilder. Berücksichtigen Sie außerdem die Maße der vorhandenen Bilder für eine optimale Darstellung.

#### Starten der Installation
Um die Installation zu starten muss der folgende Befehl in Ubuntu eingegeben werden:

	sudo bash /home/USERNAME/wm-install.sh

#### Beantworten der Nutzerinteraktion
Zu Beginn der Installation werden einige Information von Ihnen abgefragt, die für die Installation vonnöten sind. Diese Informationen werden in einem Dialog abgefragt, der sich selbst erklärt. Folgende Informationen werden abgefragt:
	
	- Anwendungsname (Die Web-Map-Anwendung wird unter domain/ANWENDUNGSNAME erreichbar sein)
	
	- Datenbankname
	
	- Datenbankpasswort
	
	- Domain
	
	- E-Mail-Adresse (Optional, aber empfohlen. Diese Email wird nur benutzt, um Sie über eventuelle Probleme mit Ihrem TLS/SSL-Zertifikat zu informieren)
Sollten Sie zwei leere, unpartitionierte Festplatten im System haben, werden Sie zusätzlich nach der zu verwendenden Festplatte gefragt.

#### Installation abwarten
Nach Durchlaufen der Nutzerinteraktion startet die Installation und Konfiguration der Web-Map-Anwendung und aller benötigter Komponenten. Die Installationszeit beträgt erfahrungsgemäß ca. 5 Minuten.

### Nach der Installation

#### Programmausgabe
Nach der erfolgten Installation werden Ihnen folgenden Informationen angezeigt:

	- Nutzername
	
	- Datenbankname
	
	- Datenbankpasswort
	
	- Inhalt der PGSERVICEFILE
	
	- Domain unter der die Anwendung erreichbar ist

#### Weitere Schritte
Besuchen Sie Ihre Anwendung unter der angegeben Domain und überprüfen Sie, ob die Anwendung über https sicher erreichbar ist.
Erstellen Sie auf Ihrem Computer eine Datei mit dem Namen pg_service.conf und kopieren Sie den Inhalt der PGSERVICEFILE in die neue Datei.
Legen Sie eine Systemvariable PGSERVICEFILE an, die den Dateipfad zur Datei pg_service.conf enthält. 
Unter Windows öffnen Sie dazu die Eingabeaufforderung mit: WINDOWS + cmd + Enter und geben folgenden Befehl ein: 

	setx PGSERVICEFILE "Dateipfad\pg_service.conf" 
Zum Beispiel:

	setx PGSERVICEFILE "C:\Users\USERNAME\pg_service.conf"'
Öffnen Sie QGIS und laden die Erweiterung Lizmap (nicht Lizmap server) herunter.
Erstellen Sie eine neue PostGIS Verbindung in QGIS, indem Sie den Namen des Services angeben, der in der PGSERVICEFILE in eckigen Klammern definiert ist und testen diese.

#### Hochladen von Projekten
Erstellen Sie ein Projekt in QGIS und speichern es als .qgs, statt .qgz. Dieses Projekt darf Layer enthalten, die in der PostGIS Datenbank gespeichert sind. Für Layer, die in der Web-Map-Anwendung bearbeitet werden sollen, ist dies sogar erforderlich. Alle anderen Layer sollten im selben Ordner wie das Projekt oder in entsprechenden Unterordnern liegen.
Nehmen Sie Ihre bevorzugten Einstellungen im Tab QGIS Server der Projekteinstellungen vor und speichern Sie das Projekt.
Öffnen Sie das Lizmap Plugin, nehmen Sie die gewünschten Einstellungen vor und speichern das QGIS Projekt erneut.
Verschieben Sie den Projektordner in seiner bestehen Struktur (z.B per FileZilla) auf den Ubuntu unter /home/USERNAME/ANWENDUNGSNAME/projektordner. Dieser Ordner muss neben der .qgs-Projektdatei und allen Layern, die nicht in PostGIS gespeichert sind, auch die vom Lizmap-Plugin erstellte Datei projektname.qgs.cfg enthalten.

#### Nutzung des Mediendownloads
Dateien, die Sie ihren Nutzern zum Download anbieten wollen, müssen Sie ausgehend vom Projektordner im Verzeichnis projektordner/media/Download ablegen.
Um die neue Downloadfunktion zu aktivieren (und auch um gegebenenfalls neu hinzugefügte Dateien freizugeben), geben Sie als Nutzer angemeldet auf dem Ubuntu den folgenden Befehl ein:

	sudo python3 /home/USERNAME/wm-projects.py
	
#### Nutzung des Medienuploads
Erstellen Sie einen Feature-Layer mit mindestens einem Textfeld und laden diesen nach PostGIS hoch.
Binden Sie den PostGIS-Layer in Ihrem Projekt ein. Wählen Sie im Tab Attributformular der Layer Eigenschaften als Bedienelement "Anhang" aus.
Fahren Sie wie gewohnt mit dem Hochladen des Projekts fort.
Um die Uploadfunktion zu aktivieren, geben Sie als Nutzer auf dem Ubuntu den folgenden Befehl ein:

	sudo python3 /home/USERNAME/wm-projects.py
	
#### Aktivieren des Projekts in der Web-Anwendung
Melden Sie sich als Admin in der Web-Anwendung an. Klicken Sie auf Administration und dann auf Kartenverwaltung.
Legen Sie ein neues Verzeichnis an und geben dazu den Ordnerpfad des hochgeladenen Projektordners an. Aktivieren Sie das Kästchen "Für dieses Verzeichnis eigene Themen/Javascript-Code" erlauben.


#### Sonstiges
Weitere Anweisungen finden Sie in der Dokumentation von Lizmap unter: https://docs.lizmap.com/current/en/index.html
