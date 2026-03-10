# BigData01 - prepare WSL (Windows Subsystem for Linux)

# Guide to preparing a fresh WSL — faster and easier than using a virtual machine

We use a new, fresh distro so an existing distribution is not affected.  
See e.g. the guide at [](https://superuser.com/questions/1515246/how-to-add-second-wsl2-ubuntu-distro-fresh-install)

1. Download a tar archive, e.g. for Distro 23-10 from [](https://cloud-images.ubuntu.com/wsl/mantic/current/ubuntu-mantic-wsl-amd64-wsl.rootfs.tar.gz)  
   or preferably for 24.04 (since this image includes `systemd`) from [](https://cloud-images.ubuntu.com/wsl/noble/current/ubuntu-noble-wsl-amd64-ubuntu.rootfs.tar.gz)

2. If never used before, enable WSL first (in `cmd.exe` or PowerShell, each as Administrator).  
   (It may also be necessary to enable `Hyper-V` first if not set.)  
   If you see errors about missing parameters in `wsl.exe` you may need to restart Windows.

```powershell
dism.exe /online /enable-feature /all /featureName:Microsoft-Hyper-V
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
wsl --set-default-version 2
```

Important: It may be necessary to restart Windows, especially after errors that `wsl.exe` cannot find parameters.  
If you encounter an error like `WslRegisterDistribution failed with error: 0x800701bc` run:

```powershell
wsl --update
```

Install a distribution:

```powershell
wsl --install -d Ubuntu-24.04
```

(The following steps can be skipped if there is already an active distro.)

3. Install and register this distro in `cmd.exe`  
   (Assumption: the downloaded file `.\ubuntu-noble-wsl-amd64-ubuntu.rootfs.tar.gz` was saved to `\%USERPROFILE\%\Downloads`)

```powershell
cd %USERPROFILE%\Downloads
wsl.exe --import Ubuntu-24.04 %USERPROFILE%\AppData\Local\Packages\Ubuntu-24.04 .\ubuntu-noble-wsl-amd64-ubuntu.rootfs.tar.gz
# or: .\ubuntu-mantic-wsl-amd64-wsl.rootfs.tar.gz
wsl --setdefault Ubuntu-24.04
wsl -d Ubuntu-24.04
```

When the Linux prompt appears, continue with script `01c_install_hadoop.md`.

Depending on the distribution, `systemd` may not be enabled. In that case add the following entry to /etc/wsl.conf in the [boot] section:

>[boot]<br>
>systemd=true


then terminate and reconnect WSL with
```powershell
wsl.exe --terminate <Distro>
```

It is also useful to prevent /etc/hosts from being overwritten by Windows on each start by adding the following line to /etc/wsl.conf in the [network] section:

>[network]<br>
>generateHosts=false