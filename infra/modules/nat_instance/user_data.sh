#!/bin/bash
set -euxo pipefail
exec > >(tee -a /var/log/user-data.log) 2>&1
echo "=== NAT instance bootstrap: $(date) ==="

# Enable IP forwarding
sysctl -w net.ipv4.ip_forward=1
echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-nat.conf

# Install and configure nftables
dnf install -y nftables
systemctl enable --now nftables

# Resolve primary interface
PRIMARY_IFACE=$(ip -o -4 route show to default | awk '{print $5}')

# NAT rules
cat > /etc/sysconfig/nftables.conf <<EOF
table ip nat {
    chain postrouting {
        type nat hook postrouting priority 100;
        oifname "$${PRIMARY_IFACE}" masquerade
    }
}
EOF

systemctl restart nftables
echo "=== NAT instance ready: $(date) ==="
