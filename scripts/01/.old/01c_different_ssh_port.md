# BigData01 - configure SSH to use a different port

The following link describes the issues with configuring the ssh port on Ubuntu 24.04 or later
[Ubuntu Discourse post](https://discourse.ubuntu.com/t/sshd-now-uses-socket-based-activation-ubuntu-22-10-and-later/30189)

Despite changing the port to a port other than 22, the output of the following command still shows port 22.

```bash
service ssh status
```

In Ubuntu 22.10, Ubuntu 23.04, and Ubuntu 23.10, on upgrade users who had configured Port settings or a ListenAddress setting in `/etc/ssh/sshd_config`
will find these settings migrated to `/etc/systemd/system/ssh.socket.d/addresses.conf`.
(As an exception, if more than one ListenAddress setting is declared, the configuration is not migrated
because systemd’s ListenStream has different semantics: any address configured which is not present at boot time
would cause the ssh.socket unit to not start. Because it is not possible to reliably determine at upgrade time whether ssh.socket
could fail to start on reboot, if you have more than one ListenAddress configured, your system will not be migrated to socket-based
activation but instead the daemon will be started on boot as before.)

Please run the following so that the `Port 10222` setting from `/etc/ssh/sshd_config` is used.

```bash
systemctl disable --now ssh.socket
rm -f /etc/systemd/system/ssh.service.d/00-socket.conf
rm -f /etc/systemd/system/ssh.socket.d/addresses.conf
systemctl daemon-reload
systemctl enable --now ssh.service
service ssh restart
service ssh status
```

The following command should show port 10222 as the listening port:
```bash
service ssh status
```

