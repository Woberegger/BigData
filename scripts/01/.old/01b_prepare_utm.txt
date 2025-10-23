## Anleitung, um UTM Virtualisierung auf MAC OS zu verwenden
# download über z.B. https://mac.getutm.app/

# Nachdem das CLI Interface über UTM es nicht zulässt, Copy + Paste mit Shift + Insert durchzuführen,
# ist es am besten, sich einfach per SSH auf die VM zu connecten
# den public SSH key kann man einfach mit folgendem Befehl auf die VM kopieren:
ssh-copy-id -i ~/.ssh/id_rsa <username>@<vm-ip> 
# Um die Web Dashboards von Hadoop vom Rechner aus zu erreichen, muss man (als root user) die Ports 9870 & 8088 in der Firewall permitten
ufw allow 9870
ufw allow 8088
# wenn mehr als 1 Node verwendet wird, muss man das Netzwerk in UTM konfigurieren, dass beide Nodes im selben NAT-Network im Network Mode "Shared Network" sind
# dazu im UTM Interface mit Rechtsklick auf die VM --> Edit --> Network
# WICHTIG: damit die kopierte VM eine neue randomisierte MAC Adresse bekommt, den Button "Random" anklicken

# in /etc/netplan auf beiden Maschinen eine statische Adresse anstelle von DHCP konfigurieren, z.B. in 192.168.0.0/16 Netzwerk

# Weiters ist der Default-GW darin zu konfigurieren mit der IP des Hosts, üblicherweise 192.168.x.1