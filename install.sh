#!/usr/bin/env bash
# Installs agent-queue for the current user: commands in ~/.local/bin, config, systemd user service, skill.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p ~/.local/bin ~/.config/fila ~/.config/systemd/user ~/.claude/skills
install -m 755 bin/fila bin/fila-daemon ~/.local/bin/
[ -f ~/.config/fila/config.json ] || cp config.example.json ~/.config/fila/config.json
sed "s#@BIN@#$HOME/.local/bin#" systemd/fila-daemon.service > ~/.config/systemd/user/fila-daemon.service
systemctl --user daemon-reload
systemctl --user enable --now fila-daemon
# skill for every Claude config dir found (one per account)
for d in ~/.claude ~/.claude-*; do
  [ -d "$d" ] && mkdir -p "$d/skills" && cp -r skills/agent-queue "$d/skills/"
done
echo "ok: edit ~/.config/fila/config.json (keeper_session, tmux_socket, rust_targets), then: fila status"
