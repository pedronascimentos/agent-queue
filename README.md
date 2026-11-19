# agent-queue

A tiny queue so several coding agents (Claude Code sessions, on one or more accounts) can share one
machine's **Android emulator, physical phone, RAM and disk** without fighting over them or waiting for hours.

- Agents call a one-line command (`fila`) to ask for a resource, wait **in the background** while they keep
  working, and hand it back with a list of what can be deleted.
- A small daemon grants turns in order, **frees disk/RAM before each turn**, pings the agent in its tmux
  pane, expires abandoned leases, and asks a "keeper" session for help only when it can't free enough itself.
- Includes a Claude Code **skill** that teaches agents the protocol, and a guide for
  **session-to-session communication** (`docs/COMMUNICATION.md`).

Outputs are single short lines on purpose: agents spend very few tokens using it.

## Install

```bash
git clone https://github.com/pedronascimentos/agent-queue && cd agent-queue
./install.sh                      # ~/.local/bin/fila, fila-daemon (systemd --user), skill in ~/.claude*/skills
$EDITOR ~/.config/fila/config.json   # keeper_session, tmux_socket, rust_targets, allowed/forbidden delete paths
fila status
```

Requirements: Linux, Python 3, systemd (user), tmux (for pings). Docker and Gradle cleanups run only if present.

## Protocol

```text
fila entrar  AGENT -r emulador|celular|pesado --ram GB --disco GB --min N --motivo "why"
fila esperar AGENT            # run in background; exit 0 = your turn
fila renovar AGENT            # every ~20 min, or the lease expires and passes on
fila sair    AGENT --apagar build/ captures/ /tmp/x   # release + what the daemon may delete
fila status
```

(English aliases: `join`, `wait`, `renew`, `leave`, `help`.) `AGENT` is the agent's tmux session name.

Resources: `emulador` (Android emulator), `celular` (physical phone), `pesado` (heavy job, no device).
`capacity` in `config.json` sets how many agents may hold each resource at once (default: emulator 1, phone 1, heavy 4; a shared heavy slot is only granted if the new request still fits in free RAM). Add resources in `resources`.

## What the daemon frees before a turn

Disk, cheapest first and only until the request fits: npm cache → Docker build cache and dangling images →
Gradle per-version caches (only when no Gradle is running) → stale Rust incremental dirs (> 2 h) in `rust_targets`.
RAM: drops page cache; for an emulator turn, stops orphan emulators. Nothing else is killed.
If it's still short, it messages `keeper_session` and grants anyway with a warning.

Deletes requested via `--apagar` are limited to `allowed_delete` and never touch `forbidden_delete`.

## Teaching the agents

Paste this once into each session (replace AGENT), or install the skill:

> Before using the emulator, the phone or anything heavy, run `fila entrar AGENT -r … --ram … --disco …`,
> then `fila esperar AGENT` in the background and keep working on other things. On your turn, renew every
> 20 min; when done, save, stop the emulator/Gradle, and run `fila sair AGENT --apagar <deletable paths>`.

## Files

- `bin/fila`: CLI (state in `~/.local/state/fila/estado.json`, guarded by `flock`)
- `bin/fila-daemon`: the scheduler (log in `~/.local/state/fila/log`)
- `skills/agent-queue/SKILL.md`: Claude Code skill
- `docs/COMMUNICATION.md`: how sessions message each other, reply markers, relay rules
- `systemd/fila-daemon.service`, `install.sh`, `config.example.json`

MIT license.
