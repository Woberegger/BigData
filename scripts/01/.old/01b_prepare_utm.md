# BigData01 - preparation for UTM virtualization

## Guide to using UTM virtualization on macOS

download via e.g. [](https://mac.getutm.app/)

Since the UTM CLI does not allow Copy + Paste with Shift + Insert, it's best to simply connect to the VM via SSH.  
You can copy the public SSH key to the VM with the following command:

```bash
ssh-copy-id -i ~/.ssh/id_rsa <username>@<vm-ip>
```

To reach the Hadoop web dashboards from the host, you must (as root) allow ports `9870` and `8088` in the firewall:

```bash
ufw allow 9870
ufw allow 8088
```

If more than one node is used, configure the network in UTM so both nodes are in the same NAT network in Network Mode \"Shared Network\".  
In the UTM interface: right-click the VM -> Edit -> Network.  
IMPORTANT: to give the copied VM a new randomized MAC address, click the `Random` button.

In `/etc/netplan` on both machines configure a static address instead of DHCP, e.g. in the `192.168.0.0/16` network.

Also configure the default gateway there to the host's IP, usually `192.168.x.1`.