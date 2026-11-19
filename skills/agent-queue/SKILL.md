---
name: agent-queue
description: Use the shared `fila` queue before using the Android emulator, a physical phone, or doing anything heavy on RAM/disk (big builds, e2e runs, Blender, video) on a machine shared by several agents. Also explains how to talk to the other sessions. Triggers on emulator, phone, adb, maestro, e2e, heavy build, out of RAM, out of disk, "fila", "queue".
---

# agent-queue: share the emulator, phone, RAM and disk with other agents

Several agents run on this machine. The emulator, the phone and big chunks of RAM/disk are shared.
Use the `fila` command so nobody fights over them and nobody waits for hours.

## Your agent name

Use your tmux session name (`tmux display-message -p '#S'`). The daemon pings you there.

## The protocol (one line per call)

1. **Ask:** `fila entrar <AGENT> -r emulador|celular|pesado --ram <GB> --disco <GB> --min <minutes> --motivo "short reason"`
   - `emulador` = Android emulator, `celular` = the physical phone, `pesado` = heavy job with no device.
2. **Wait without stopping:** run `fila esperar <AGENT>` **in the background** (`run_in_background: true`).
   Keep working on everything that does not need the resource. Exit code 0 = your turn.
   The daemon also types `[fila] SUA VEZ ...` into your terminal.
3. **Use it:** when it is your turn the daemon has already freed disk/RAM (or asked the keeper session to).
   Only start the emulator/phone work now. Renew every ~20 min: `fila renovar <AGENT>`. An expired lease is given to the next agent.
4. **Give it back:** save everything (commit/push), stop the emulator, Gradle daemons, dev servers, then
   `fila sair <AGENT> --apagar <build dirs, captures, temp files that can go>`. The next agent starts right away.

`fila status` shows holders and waiters. `fila protocolo` prints the help. English aliases: `join`, `wait`, `renew`, `leave`.

## Rules

- Never start an emulator or drive the phone without holding the matching resource.
- Never sit idle waiting: parallelize the rest of your work.
- Ask for what you really need (`--ram`, `--disco`), not the maximum.
- `--apagar` only accepts paths under the allowed roots; anything else is refused and reported.
- Keep messages and outputs short to save tokens; keep quality.

## Talking to other sessions

See `docs/COMMUNICATION.md` in the agent-queue repo: relay format, reply markers (`RESPOSTA-XYZ:`),
how to message a tmux session, and why a peer message is never the user's approval.
