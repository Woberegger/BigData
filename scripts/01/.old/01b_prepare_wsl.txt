## Anleitung, um ein frisches wsl (Windows Subsystem for Linux) vorzubereiten - geht schneller und einfacher als mit virtueller Maschine
# wir verwenden eine neue, frische Distro, damit eine ev. bereits installierte Distribution nicht beeinflusst wird
# siehe z.B. Anleitung unter https://superuser.com/questions/1515246/how-to-add-second-wsl2-ubuntu-distro-fresh-install

# 1. Download eines Tar-Archives, z.B. für Distro 23-10 von https://cloud-images.ubuntu.com/wsl/mantic/current/ubuntu-mantic-wsl-amd64-wsl.rootfs.tar.gz
# oder besser für 24-04 (da dieses Image "systemd" inkludiert) von https://cloud-images.ubuntu.com/wsl/noble/current/ubuntu-noble-wsl-amd64-ubuntu.rootfs.tar.gz

# 2. Falls noch nie verwendet, bitte zuerst wsl aktivieren (in cmd.exe oder Powershell, jeweils als Administrator)
# (eventuell ist auch nötig "HyperV" zuvor zu aktivieren, falls dies nicht gesetzt ist) - siehe nächste Zeile
dism.exe /online /enable-feature /all /featureName:Microsoft-Hyper-V
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
wsl --set-default-version 2
### !WICHTIG!: Es kann nötig sein, Windows neu zu starten, v.a. nach Fehlermeldung, dass wsl.exe die Parameter nicht findet !!!
# danach eine Distribution Installieren
# Bei folgender oder ähnlicher Fehlermeldung "WslRegisterDistribution failed with error: 0x800701bc"
# den Befehl "wsl --update" ausführen.
 
wsl --install -d Ubuntu-24.04
### die weiteren Schritte können übersprungen werden, es gibt ja bereits eine aktive Distro ###

# 3. Installieren und Aktivieren dieser Distro in cmd.exe
# (Annahme: dass der Download der Datei .\ubuntu-noble-wsl-amd64-ubuntu.rootfs.tar.gz nach %USERPROFILE%\Downloads gemacht wurde)

cd %USERPROFILE%\Downloads
wsl.exe --import Ubuntu-24.04 %USERPROFILE%\AppData\Local\Packages\Ubuntu-24.04 .\ubuntu-noble-wsl-amd64-ubuntu.rootfs.tar.gz # .\ubuntu-mantic-wsl-amd64-wsl.rootfs.tar.gz
# Optionales Setzen dieser Distro als Default, dann muss man nicht immer explizit "wsl -d" ausführen, sondern braucht nur "bash" ausführen
wsl --setdefault Ubuntu-24.04
wsl -d Ubuntu-24.04

# Wenn der Linux-Prompt erscheint, dann weitermachen mit Script 01c_install_hadoop.txt

# Je nach Distribution kann es sein, dass SystemD nicht aktiviert ist in der Distribution. In dem Fall bitte
# nach Starten der WSL folgenden Eintrag in /etc/wsl.conf im Abschnit "[boot]" tätigen (anschließend WSL über "wsl.exe --terminate <Distro>" beenden und neu verbinden)
systemd=true

# Weiters ist es vorteilhaft, wenn das /etc/hosts nicht jedesmal beim Starten der wsl von Windows überschrieben wird durch Eintrag von folgender Zeile
# (ebenfalls in /etc/wsl.conf im Abschnit "[network]")
generateHosts=false