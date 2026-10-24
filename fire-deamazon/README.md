# De-Amazon one Fire TV Stick (Sandeep's stick)

A personal plan for one Fire TV Stick, run by hand from atvTools on an iPhone. It lives in this fork
and is not meant for upstream: it departs from `PROMPT.md` where the owner's goals differ (it uses
`pm uninstall --user 0` as well as `pm disable-user`, and the launcher is not this repo's).

Provenance labels used in every file:

- **DIRECT**: the owner said it.
- **DOCUMENT**: from a file in this repo or a cited web source.
- **AUDIT**: read from the owner's own stick (pasted output).
- **INFERENCE**: reasoned, not verified on this stick.
- **UNRESOLVED**: not verified, so kept out of every batch.

## Status

| Step | File | State |
|---|---|---|
| 0. Read-only audit and on-stick backup | [00-audit.md](00-audit.md), results in [audit-log.md](audit-log.md) | 0.1 to 0.4 and 0.6 done; backup complete; 0.5 full list pending |
| 1. Current-state and gap analysis | `01-gap-analysis.md` | Waits for the audit output |
| 2. Stages A-D: uninstall, disable, OTA/verification, app lifecycle | `02-plan.md` | Waits for the audit output |
| Ceiling: what full ownership needs | [ceiling.md](ceiling.md) | Done for AFTSS on PS7717: shell-only |
| Quit-on-exit research | [lifecycle.md](lifecycle.md) | Done; SDK 28, so the recommended per-app restriction is available |
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
