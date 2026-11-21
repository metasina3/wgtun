#!/usr/bin/env bash
set -euo pipefail
[[ $EUID == 0 ]] || { echo 'Run with sudo bash install.sh' >&2; exit 1; }
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
for tool in ip iptables wg wg-quick systemctl; do
  command -v "$tool" >/dev/null || { echo "Missing dependency: $tool" >&2; exit 1; }
done
if systemctl is-active --quiet wgtun.service; then
  echo 'Stop wgtun before upgrading.' >&2; exit 1
fi
install -Dm755 wgtun /usr/local/sbin/wgtun
install -Dm644 wgtun.service /etc/systemd/system/wgtun.service
if [[ ! -e /etc/wireguard/wgtun0.conf ]]; then
  install -Dm600 wgtun0.conf.example /etc/wireguard/wgtun0.conf
fi
systemctl daemon-reload
printf '%s\n' 'Edit /etc/wireguard/wgtun0.conf, then run sudo wgtun on.'
