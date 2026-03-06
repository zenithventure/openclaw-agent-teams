#!/bin/bash
# Run as openclaw user after curl -fsSL https://openclaw.ai/install.sh | bash

# 1. Add session env vars permanently
echo '' >> ~/.bashrc
echo 'export XDG_RUNTIME_DIR=/run/user/$(id -u)' >> ~/.bashrc
echo 'export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus' >> ~/.bashrc

# Apply immediately
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus

# 2. Fix Telegram groupPolicy in openclaw.json
CONFIG=~/.openclaw/openclaw.json
if [ -f "$CONFIG" ]; then
    sed -i 's/"groupPolicy": "allowlist"/"groupPolicy": "open"/' "$CONFIG"
    echo "Patched groupPolicy to open in $CONFIG"
else
    echo "Warning: $CONFIG not found — skipping groupPolicy patch"
fi

# 3. Create systemd user dir and unit file manually
#    (bypasses the chicken-and-egg bug in 'openclaw gateway install')
mkdir -p ~/.config/systemd/user/

cat > ~/.config/systemd/user/openclaw-gateway.service << 'EOF'
[Unit]
Description=OpenClaw Gateway
After=network.target

[Service]
Type=simple
ExecStart=/home/openclaw/.npm-global/bin/openclaw gateway start
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

# 4. Enable and start the stub service so the check passes
systemctl --user daemon-reload
systemctl --user enable openclaw-gateway.service
systemctl --user start openclaw-gateway.service

# 5. Now let openclaw rewrite the unit file properly with the correct token
sleep 3
openclaw gateway install --force

echo ""
echo "Done. Check status with:"
echo "  systemctl --user status openclaw-gateway.service"
echo "  journalctl --user -u openclaw-gateway.service -f"
