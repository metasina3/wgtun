# wgtun

[راهنمای فارسی](README.fa.md)

Route new, locally initiated IPv4 connections from a Linux host through a WireGuard endpoint on an egress VPS. Replies to tracked inbound connections and forwarded traffic (including typical bridged containers) stay outside this policy. Host-network containers are not excluded. This is not a VPN kill switch: IPv6, private destinations, and traffic before startup or after shutdown can go direct. Private DNS resolvers may also be reached directly.

## Quick install

On Debian/Ubuntu with systemd, paste this single line as a user with `sudo` access:

```sh
bash -c 'set -eu; sudo apt-get update; sudo apt-get install -y ca-certificates curl tar wireguard-tools iproute2 iptables; d=$(mktemp -d); trap "rm -rf -- \"$d\"" EXIT; cd "$d"; url=https://github.com/metasina3/wgtun/releases/download/v0.1.1; pkg=wgtun-v0.1.1.tar.gz; curl -fsSL -O "$url/$pkg" -O "$url/$pkg.sha256"; sha256sum -c "$pkg.sha256"; tar -xzf "$pkg"; sudo bash wgtun-v0.1.1/install.sh'
```

This installs dependencies, verifies and extracts the release, and installs `wgtun`. Existing config is preserved. The service stays off until you configure your endpoint and start it.

## Configuration

1. On the egress VPS, configure a WireGuard interface (for example `10.77.0.1/24`, UDP `51820`), allow the WireGuard UDP port in its firewall, and add the client’s public key with `AllowedIPs = 10.77.0.2/32`. Enable persistent `net.ipv4.ip_forward=1`. Configure forwarding from WireGuard to the public interface, allow established/related return traffic, and masquerade the tunnel subnet on the public interface. Integrate these rules into your existing firewall; do not replace it.
2. On the client, generate a separate WireGuard keypair per host (`wg genkey` and `wg pubkey`); keep private keys local. Edit `/etc/wireguard/wgtun0.conf` with `sudoedit`. Replace sample keys and `203.0.113.10:51820` with your VPS public endpoint. Keep file mode `0600`, `Table = off`, and peer `AllowedIPs = 0.0.0.0/0`. Omit DNS, hooks, FwMark, and SaveConfig.
3. Keep console access. Start `sudo wgtun on`, check `sudo wgtun status` and `sudo wg show wgtun0`, then make a fresh IPv4 request to an IP-check service and verify it reports your VPS public IP. Check inbound SSH separately before boot enablement: `sudo systemctl enable wgtun.service`. Service status alone does not prove handshake or connectivity.

## Operations

- `sudo wgtun off`: remove policy and restore direct egress for new flows.
- `sudo wgtun restart`: reload edited config; existing connections can break during restart.
- `sudo journalctl -u wgtun.service`: inspect startup or cleanup errors.
- Uninstall: run `sudo systemctl disable --now wgtun.service`, remove `/usr/local/sbin/wgtun` and `/etc/systemd/system/wgtun.service`, then run `sudo systemctl daemon-reload`. Config remains; remove it separately if no longer needed.

Do not run alongside another manager of `wgtun0`. Reserve route table `51888`, rule priority `10588`, chain `WGTUN_OUTPUT`, and mark bits `0x40000000` and `0x20000000`. Existing firewall, policy routing, and conntrack rules can affect behavior. If endpoint resolves by DNS, startup needs working DNS before the tunnel is up.
