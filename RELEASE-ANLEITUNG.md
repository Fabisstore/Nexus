# Nexus – Windows Installer & Updates

## Einmalige Einrichtung

1. Dieses Projekt in ein GitHub-Repository namens `Nexus` unter dem Konto `Fabisstore` hochladen.
2. GitHub Actions aktiv lassen.
3. Einen Tag wie `v0.4.0` veröffentlichen.
4. Der Workflow baut auf einem echten Windows-Runner den NSIS-Installer und veröffentlicht ihn als GitHub Release.

## Für Nutzer

Die Datei `Nexus-Setup-0.4.0.exe` wird einmal installiert. Danach ist Nexus normal über Startmenü/Desktop erreichbar.

## Updates

Für eine neue Version die Versionsnummer in `package.json` erhöhen und einen Tag mit `v` davor veröffentlichen, z.B. `v0.4.1`.
GitHub baut daraus automatisch einen neuen Release.
Installierte Nexus-Versionen prüfen automatisch auf Updates. Bei einem verfügbaren Update kann die App den Download starten und nach Bestätigung neu starten.

## Hinweis

Der Installer kann hier nicht lokal erzeugt werden, weil diese Entwicklungsumgebung kein Windows-Buildsystem besitzt. Der GitHub-Windows-Runner übernimmt genau diesen Schritt.
