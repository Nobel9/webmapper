## Importiere benötigte Python-Module
from glob import glob
import os
import subprocess

## Definiere allgemeine Variable
download_folder = 'media/Download/'
js_folder = 'media/js/'
js_folder_default = js_folder + 'default/'
upload_folder = 'media/upload/'

## Unterstütz den Anwendungsadmin bei der Einrichtung von Datendown- und -uploads, für Downloads wird automatisiert ein JavaScript-Skrit geschrieben
def configure_wm_projects(myuser, myappname):

    ## Nutzerhinweis
    print('Erstelle Java-Script Dateien, die den Download von Dateien im Ordner PROJEKT/media/Download ermöglichen')

    ## Lese alle Ordner unter /home/$myuser/$myappname aus
    folders = glob('/home/' + myuser + '/' + myappname + '/*/')

    ## Iteriere durch die Ordner
    for folder in folders:
    
        ## Prüfe ob der ausgewälte Ordner der automatisch erstellte Ordner lost+found ist, falls ja beachte diesen nicht weiter
        if 'lost+found' not in folder:
        
            ## Legt falls nichts vorhanden den Unterordner projektordner/media an
            if glob(folder + 'media/') == []:
                os.mkdir(folder + 'media/')
                
            ## Legt falls nichts vorhanden den Unterordner projektordner/media/upload an
            if glob(folder + upload_folder) == []:
                os.mkdir(folder + upload_folder)
                
            ## Greift aus Python per subprocess auf Bash zu und gibt www-data Schreibrechte auf dem Upload Ordner
            subprocess.run(['sudo', 'chown', myuser + ':www-data', folder + upload_folder])
                
            ## Nutzerhinweis
            print('Überprüfe Ordner:', folder)
            
            ## Speichere alle Dateien im Ordner Download in die Liste datalist
            datalist = glob(folder + download_folder + '*')
            
            ## Folgendes wird nur ausgeführt wenn Dateien im Download Ordner zu finden sind
            if datalist != []:
                
                ## Nutzerhinweis
                print('Foldende Dateien werden zum Download bereitgestellt:', datalist)
                
                ## Legt falls nichts vorhanden den Unterordner projektordner/media/js an
                if glob(folder + js_folder) == []:
                    os.mkdir(folder + js_folder)
                    
                ## Legt falls nichts vorhanden den Unterordner projektordner/media/js/default an
                if glob(folder + js_folder_default) == []:
                    os.mkdir(folder + js_folder_default)
                    
                ## Speichere Standard Inhalt Teil 1 der JS-Datei zum Download in die Variable string
                string = "lizMap.events.on({'uicreated':function(evt){\n\n"
                string += "    lizMap.addDock('Download','Download','dock','','icon-download-alt');\n"
                string += '    var mediadok = OpenLayers.Util.urlAppend(lizUrls.media,OpenLayers.Util.getParameterString({"repository": lizUrls.params.repository,"project": lizUrls.params.project,"path": "media/Download/"}));\n\n'

                ## Hänge je Datei aus datalist die Definition eines Downloadbuttons mit hinterlegtem Dateipfad der Variable string an
                for i in range(len(datalist)):
                    dataname = datalist[i].split('/')
                    dataname = dataname[len(dataname) - 1]
                    string += "    button" + str(i) + " =  '<button id=\"button" + str(i) + "\" class=\"btn btn-secondary\"> <span class=\"icon-green icon-download-alt\"></span>" + dataname + "</button>';\n"
                    string += "    $('#Download').append(button" + str(i) + ");\n"
                    string += "    $('#button" + str(i) + "').click(function myfunction() {window.open(mediadok +'" + dataname + "');})\n"
                    string += "    $('#button" + str(i) + "').css('margin', '10px 5px').css('display','block').css('width','80%')\n\n"

                ## Hänge Standard Inhalt Teil 2 der JS-Datei zum Download an die Variable string an
                string += "    x1 = document.getElementById('Download');\n"
                string += "    y1 = x1.getElementsByClassName('menu-content');\n"
                string += '    y1[0].style.background ="rgba(0,0,0,0.1)";\n\n'
                string += '}});'
        
                ## Schreibe Inhalt der Variable string in die JavaScript-Datei projektordner/media/js/default/wm-download.js
                with open(folder + js_folder_default + 'wm-download.js', 'w') as file:
                    file.write(string)