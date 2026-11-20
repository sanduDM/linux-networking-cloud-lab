# 03 - Deployment

Steps: create the VM, configure Linux, secure access, deploy a service, test connectivity.

## 1. Create the VM

I used the AWS EC2 console in the Asia Pacific (Sydney) region.

- Name: `linux-lab-server`
- Image: Ubuntu Server 24.04 LTS
- Type: `t3.micro` (free tier)
- Key pair: new ED25519 key pair, `.pem` file
- Security group: SSH from my own IP only
- Storage: 8 GiB

I wanted the Singapore region at first, but the console was already in Sydney and it works the same, so I kept it. [Change this if it is not true for you.]

![EC2 instance](../screenshots/01-ec2-instance.png)

## 2. Configure Linux

I updated the server and practised commands for files, permissions, users, groups, processes and services. See [01-linux-basics.md](01-linux-basics.md).

## 3. Secure access

- made my own SSH key and installed the public key on the server
- turned off password login and root login
- limited SSH in the security group to my own IP
- turned on UFW with only ports 22 and 80 allowed

See [01-linux-basics.md](01-linux-basics.md) and [02-networking.md](02-networking.md).

## 4. Deploy Nginx

```bash
sudo apt install -y nginx
sudo systemctl enable --now nginx
```

Then I wrote my own web page to `/var/www/html/index.html` (a copy is in `configs/index.html`) and checked it:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

I opened `http://<PUBLIC_IP>` in my browser and the page loaded.

![Deployed page](../screenshots/13-nginx-page.png)

## 5. Test connectivity

I tested from the inside of the server to the outside, one step at a time:

1. `curl -I http://localhost` on the server. Result: `200 OK`, so Nginx works.
2. `sudo ss -tlnp | grep :80`. Nginx is listening on port 80.
3. `sudo ufw status`. Ports 22 and 80 are allowed.
4. `Test-NetConnection <PUBLIC_IP> -Port 80` on my laptop. Result: `True`, so the security group allows it.
5. Opened the page in the browser. It loaded.

If something fails, I check in the same order: service, port, UFW, then security group.

![Connectivity tests](../screenshots/14-connectivity-tests.png)

I also watched the Nginx access log while refreshing the page:

```bash
sudo tail -f /var/log/nginx/access.log
```

Each line shows the visitor's IP, the time, the request and the status code (200 means success).

## 6. Problems I had

- The `.pem` key gave an "UNPROTECTED PRIVATE KEY FILE" error. I fixed the file permissions with `icacls`.
- The key file was not where I expected. I found it with `Get-ChildItem` and moved it to my `.ssh` folder.
- I typed a laptop command inside the server terminal and it failed. After that I checked the prompt before every command.
- The security group "My IP" option gave an IPv6 address, so I typed my IPv4 address myself.
- [Add any other problem you really had.]

## 7. Clean up

When I finished, I stopped the instance so it would not use my free plan credits. [Change this if you terminated it.]