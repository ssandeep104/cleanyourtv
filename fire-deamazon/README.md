# De-Amazon one Fire TV Stick (Sandeep's stick)

A personal plan for one Fire TV Stick, run by hand from atvTools on an iPhone. It lives in this fork
and is not meant for upstream: it departs from `PROMPT.md` where the owner's goals differ (it planned
`pm uninstall --user 0` as well as `pm disable-user`, but this firmware refuses uninstall-for-user, and the launcher is not this repo's).

Provenance labels used in every file:

- **DIRECT**: the owner said it.
- **DOCUMENT**: from a file in this repo or a cited web source.
- **AUDIT**: read from the owner's own stick (pasted output).
- **INFERENCE**: reasoned, not verified on this stick.
- **UNRESOLVED**: not verified, so kept out of every batch.

## Status: COMPLETE (2026-10-25)

Final state and the standing note for updates: [audit-log.md](audit-log.md), "Project complete". If the
staged Fire OS update ever installs, run a fresh CHECK and re-verify the whole tuned state before anything else
(`bash fire-deamazon/tune.sh --verify`: 195 enabled, 58 disabled since round 2); an update may turn things back on.

Follow-up tried 2026-10-25: clearing the staged update with `pm clear` was **refused** (protected package), so it
cannot be cleared from the shell: [06-ota-clear.md](06-ota-clear.md). Standing posture: forced updater disabled,
a look at About now and then, and the full re-check above if the build ever changes.

| Step | File | State |
|---|---|---|
| 0. Read-only audit and on-stick backup | [00-audit.md](00-audit.md), results in [audit-log.md](audit-log.md) | Complete (0.0 to 0.9, 0.5c, 0.5d) |
| 1. Current-state and gap analysis | [01-gap-analysis.md](01-gap-analysis.md) | Done |
| 2. Stages A-D: disable apps, disable services, OTA/verification, app lifecycle | [02-plan.md](02-plan.md) | Complete: A, B1 to B7, C1 (partial, shell ceiling), C2, D1, D2; plus firebat and spiderpork disabled; Netflix and AIO Streamer removed |
| Runbook for a phone-driving agent (all remaining steps) | [03-runbook.md](03-runbook.md) | Run through C0 by the owner's agent; C1 and C2 applied by hand |
| Continuation runbook (C1 checks, C2 proof, stage D, final owner checks) | [04-continuation-runbook.md](04-continuation-runbook.md) | Ran in part until the phone harness failed; reconciled in audit-log |
| Final runbook (D1 checks, casting, persistence, D2), manual | [05-final-runbook.md](05-final-runbook.md), snippets in [snippets.md](snippets.md) | Complete (run by hand) |
| Ceiling: what full ownership needs | [ceiling.md](ceiling.md) | Done for AFTSS on PS7717: shell-only |
| Quit-on-exit research | [lifecycle.md](lifecycle.md) | Done; SDK 28, so the recommended per-app restriction is available |
| Tune script: animation scales 0.5, cache trim, verification (Mac, adb) | [tune.sh](tune.sh) | Ran 2026-10-25: PASS. Since round 2, use `--verify` for re-checks (expects 195 / 58) |
| Unresolved | [unresolved.md](unresolved.md) | Living list |

## Fixed constraints (DIRECT)

- Off limits, never in any batch: `com.conreo.couchytv` (Couchy), `io.github.toolicious.homeonfire`
  (Home On Fire and its accessibility service), `com.amazon.tv.launcher` (stock launcher, the escape hatch).
- Keep working: Stremio, stock YouTube, Downloader, Silk Browser, Netflix, Instagram, NordVPN.
- NordVPN is the one VPN. No local-VPN DNS filter unless the owner raises it.
- Never in a batch: anything behind Home handling, Settings, HDMI/inputs, Bluetooth and remote pairing,
  Wi-Fi, the package installer, or Android core packages.
- Nothing runs on the stick except by the owner, from these files.

## How a batch works

**Every batch in this project is one line**, steps joined with `;` (AUDIT: atvTools flattens a
multi-line paste into one line and Return sends it). One batch = one paste = one Return. Each step echoes
a label before it runs, so the output shows which step said `Success` or an error.

Output from `pm`, `settings` or `cmd` always goes through a pipe (`| cat > file`) before it reaches a file:
redirected straight to `/sdcard` it fails on this build (AUDIT, batch 0.3; detail in [00-audit.md](00-audit.md)).

1. Save the **restore batch** in atvTools as a snippet before anything else, so undo is one tap away.
   Do not run it yet.
2. Run the **change batch**. Check each step's `Success` or error in the output.
3. Run the **check batch**, reboot, run the check batch again, paste both outputs back.
4. Next batch only after the check is clean.
