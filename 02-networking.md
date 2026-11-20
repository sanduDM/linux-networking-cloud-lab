# 02 - Networking

This part covers IP addresses, DNS, ports and firewalls on my AWS server.

## IP addressing

```bash
ip a
hostname -I
ip route
curl -s ifconfig.me; echo
ping -c 3 8.8.8.8
ping -c 3 google.com
```

My server has two addresses:

- Private IP: `172.31.45.127/20`. This is used inside the AWS network (VPC).
- Public IP: `<PUBLIC_IP>`. This is the address people on the internet use.

`ip a` only shows the private address. AWS translates the public address to the private one (NAT), so the server never sees its public IP on its own network card. The `/20` means the subnet has 4,096 addresses. The `default via` line in `ip route` is the gateway.

I also looked at the VPC in the AWS console. The default VPC is `172.31.0.0/16` and it has three subnets (one per availability zone). My server is in the `172.31.32.0/20` subnet. The internet gateway is attached to the VPC, and the route table sends all other traffic (`0.0.0.0/0`) to the internet gateway.

![IP addressing](../screenshots/08-networking-ip.png)

## DNS

```bash
cat /etc/resolv.conf
nslookup google.com
dig google.com +short
dig MX gmail.com +short
dig NS google.com +short
dig -x 8.8.8.8 +short
cat /etc/hosts
```

DNS changes names into IP addresses. In the full `dig` output, the answer section gives the IP, the TTL says how long the answer can be cached, and the SERVER line shows which DNS server replied. The record types I tried were A (IPv4), AAAA (IPv6), MX (mail), NS (name servers) and TXT (text).

The file `/etc/hosts` is checked before DNS. The server uses the local resolver at `127.0.0.53`.

I also made a free DuckDNS name and pointed it at my public IP. [Write your subdomain result here, or delete this part if you skipped it.]

![DNS](../screenshots/09-dns.png)

## Ports

```bash
sudo ss -tulnp
```

What I found listening:

- Port 22: `sshd` (SSH), on all interfaces
- Port 80: `nginx` (web), on all interfaces
- Port 53: `systemd-resolve`, only on `127.0.0.53` (local DNS)
- Port 323: `chronyd`, only on `127.0.0.1` (time sync)
- Port 68: `systemd-network` (DHCP)

`0.0.0.0` means the service listens on every network interface, so it can be reached from outside. `127.0.0.x` is the loopback address, so only the server itself can reach those ports. `[::]` is the same as `0.0.0.0` for IPv6.

I tested ports from my laptop:

```powershell
Test-NetConnection <PUBLIC_IP> -Port 22
Test-NetConnection <PUBLIC_IP> -Port 80
```

Port 22 worked. Port 80 failed even though Nginx was listening, because the AWS security group did not allow port 80 yet.

![Ports](../screenshots/10-ports-ss.png)

## Firewalls

There are two firewalls and a request has to pass both.

**1. AWS security group** (outside the server). My rules:

- SSH, port 22, only from my own IP (`<MY_IP>/32`)
- HTTP, port 80, from anywhere (`0.0.0.0/0`)

When I created the SSH rule, "My IP" gave me an IPv6 address, but my server uses IPv4. I changed the source to Custom and typed my IPv4 address with `/32`.

![Security group](../screenshots/11-security-group.png)

**2. UFW** (inside the server):

```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw enable
sudo ufw status verbose
```

I allowed port 22 before enabling UFW so I would not lock myself out.

![UFW](../screenshots/12-ufw-status.png)

**My experiment:**

1. I removed the HTTP rule from the security group. The page stopped loading and `Test-NetConnection` failed.
2. I added the rule back. It worked again.
3. I ran `sudo ufw deny 80/tcp`. It failed again, even though the security group was open.
4. I removed the deny rule and allowed port 80. It worked again.

What I learned: either firewall can block traffic, and a blocked request just times out instead of showing an error. [Add what surprised you.]