# 01 - Linux Basics

In this part I connected to my Ubuntu 24.04 server on AWS and practised the basic Linux commands.

## Connecting to the server

I used SSH from PowerShell with the key file I downloaded when I created the server.

```powershell
ssh -i "$env:USERPROFILE\.ssh\lab-key.pem" ubuntu@<PUBLIC_IP>
```

At first SSH gave an "UNPROTECTED PRIVATE KEY FILE" warning because other users on my laptop could read the key. I fixed it with `icacls` so only my own user can read the file.

After logging in I updated the server:

```bash
sudo apt update && sudo apt upgrade -y
sudo reboot
uname -r
```

The update installed a new kernel, so I rebooted. `uname -r` showed the new kernel version.

![SSH login](../screenshots/02-ssh-login.png)

## Files and folders

```bash
pwd
ls -la
mkdir -p ~/lab/project
cd ~/lab
echo "Hello Linux" > hello.txt
cat hello.txt
cp hello.txt project/copy.txt
mv hello.txt project/moved.txt
rm project/copy.txt
ls -R ~/lab
```

`pwd` shows where I am. `ls -la` shows all files including hidden ones. `mkdir -p` makes folders. `echo ... > file` writes text into a file. At the end only `moved.txt` was left inside `project`, so copy, move and delete all worked.

## Permissions

```bash
touch script.sh
ls -l script.sh
chmod 755 script.sh
chmod 600 script.sh
chmod u+x script.sh
chmod go-r script.sh
chmod a+r script.sh
sudo chown root:root script.sh
sudo chown ubuntu:ubuntu script.sh
```

In `-rwxr-xr-x` the first letter is the file type, then there are three groups: owner, group and others. In numbers, r = 4, w = 2 and x = 1, so 755 means the owner has rwx and everyone else has r-x.

I also made a small script that prints the user name and ran it with `./script.sh`. I expected "Permission denied" the first time, but it ran. [Write why: the file already had execute permission, and `>` keeps the old permissions.]

![Permissions](../screenshots/03-permissions.png)

## Users and groups

```bash
id
sudo adduser devuser
sudo groupadd developers
sudo usermod -aG developers devuser
id devuser
grep devuser /etc/passwd
grep developers /etc/group
sudo chown ubuntu:developers ~/lab/project
sudo chmod 770 ~/lab/project
```

I used `-aG` so the user is added to the group without being removed from other groups. When I logged in as `devuser` and tried `sudo`, it said "devuser is not in the sudoers file". That is correct, because only users in the `sudo` group can use sudo. [Add one sentence about what you learned from this.]

![Users and groups](../screenshots/04-users-groups.png)

## Processes

```bash
ps aux | head -10
sleep 600 &
jobs
pgrep sleep
kill $(pgrep sleep)
sleep 600 & kill -9 $!
top
free -h
df -h
```

`ps aux` lists all running processes. `sleep 600 &` runs a process in the background. `kill` asks a process to stop nicely, and `kill -9` forces it to stop. `top` shows live CPU and memory use, and I pressed `q` to quit.

![Processes](../screenshots/05-processes.png)

## Services

```bash
systemctl status ssh
sudo apt install -y nginx
systemctl status nginx
sudo systemctl stop nginx
sudo systemctl start nginx
sudo systemctl restart nginx
sudo systemctl enable nginx
journalctl -u nginx --no-pager | tail -20
curl -I http://localhost
```

`systemctl` controls services. `enable` makes a service start when the server boots. `curl -I http://localhost` returned `HTTP/1.1 200 OK`, so Nginx was working inside the server.

![Nginx service](../screenshots/06-systemd-nginx.png)

## SSH keys and hardening

I made my own key pair on my laptop:

```powershell
ssh-keygen -t ed25519 -f "$env:USERPROFILE\.ssh\lab_ed25519"
```

The `.pub` file is the public key and goes on the server. I added it to `~/.ssh/authorized_keys` with `>>` so the old key was not deleted. At first I used the wrong terminal and the command failed, because I ran a PowerShell command inside the server. [Write this in your own words.]

I tested the new key in a second terminal before changing anything, and I kept my first session open in case I locked myself out.

Then I created `/etc/ssh/sshd_config.d/99-hardening.conf`:

```
PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
MaxAuthTries 3
```

```bash
sudo sshd -t
sudo systemctl restart ssh
```

Result: login with my key still worked, and a password login gave `Permission denied (publickey)`.

![SSH hardening](../screenshots/07-ssh-hardening.png)