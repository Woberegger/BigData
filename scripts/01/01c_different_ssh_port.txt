# Folgender Link beschreibt die Probleme mit der Einstellung des ssh-Ports bei Ubuntu 24-04 oder höher
https://discourse.ubuntu.com/t/sshd-now-uses-socket-based-activation-ubuntu-22-10-and-later/30189
# Trotz Änderung des Ports auf einen anderen als 22 zeigt die Ausgabe folgendes Befehls noch immer Port 22 an
service ssh status

#In Ubuntu 22.10, Ubuntu 23.04, and Ubuntu 23.10, on upgrade users who had configured Port settings or a ListenAddress setting in /etc/ssh/sshd_config will find these settings migrated to /etc/systemd/system/ssh.socket.d/addresses.conf. (As an exception, if more than one ListenAddress setting is declared, the configuration is not migrated because systemd’s ListenStream has different semantics: any address configured which is not present at boot time would cause the ssh.socket unit to not start. Because it is not possible to reliably determine at upgrade time whether ssh.socket could fail to start on reboot, if you have more than one ListenAddress configured, your system will not be migrated to socket-based activation but instead the daemon will be started on boot as before.)

# Bitte führt das folgende aus, damit die Einstellung "Port 10222" aus /etc/ssh/sshd_config genommen wird

systemctl disable --now ssh.socket
rm -f /etc/systemd/system/ssh.service.d/00-socket.conf
rm -f /etc/systemd/system/ssh.socket.d/addresses.conf
systemctl daemon-reload
systemctl enable --now ssh.service
service ssh restart
service ssh status # should show port 10222 as listening port
