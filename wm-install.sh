#!/bin/bash

#### Lade Skripte mit Variablen und Funktionen
source wm-variables.sh

#### Überprüfe ob skript als Sudo gestartet wurde
check_for_sudo

#### Definiere Variable
wm_variables_set

#### Frage Nutzer ob Installation gestartet werden soll
wm_welcome
wm_exit_check

#### Bilde Variablen für Nutzer, Datenbank und Passwort
wm_user_n
wm_exit_check
wm_log_preentry "Start der Installation"

#### Partition und Mounting der Festplatte
wm_disc_mount_master

#### QGIS-Server, Apache und ähnliches
wm_qgisserver_apache
wm_wfsoutputextension

#### Installere WebMap-Client
wm_lizmap
wm_lizmap_design
wm_lizmap_downloadscript

#### Konfiguration von PostgreSQL
wm_postgisdb

#### SSL-Zertifikat 
wm_ssl_install

#### Ende der Installation
wm_finished