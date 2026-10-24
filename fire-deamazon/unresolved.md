# Unresolved

Each item below is kept out of every batch until it is verified.

| # | Item | Why it is unresolved | What would resolve it |
|---|---|---|---|
| U1 | ~~Model, codename, Fire OS build, SDK~~ | Resolved by audit 0.1: AFTSS `sheldon`, Fire OS 7.7.1.7 PS7717, SDK 28 | Done |
| U2 | Which package enforces Amazon's app blacklist on Fire OS 7/8 | No source names it; reports say it matches package names against Amazon's cloud list. This repo's 4K 2023 list left `com.amazon.adep` (package verification) and `com.amazon.platform.fdra` (package allowlisting) alone. | Audit 0.9, then `dumpsys package` on each candidate; even then, disabling may be refused or may break installs |
| U3 | Whether the OTA packages can be disabled on this build | Protected on some Fire OS 7 builds (`afteu014`), not tried on others | Audit 0.9 shows them; a refused `pm disable-user` is a no-op, so the attempt itself is safe |
| U4 | ~~Whether the system-user exploit (tier 2) applies~~ | Resolved: does not apply, PS7717 is newer than PS7704 | Done |
| U5 | A helper app for a "Quit?" prompt on Back | None found that is verified on Fire TV | Owner names one, or we accept the gap in [lifecycle.md](lifecycle.md) |
| U6 | Home On Fire internals (what it watches, whether a second accessibility service conflicts) | Project page not found in research | Owner shares its link or the app's about screen |
| U7 | Whether Stremio is on Amazon's blocklist | Not named in any report found, but the list is private | Watch for a block screen; no action possible from the shell |
| U8 | Network-level blocking of Amazon update and telemetry hosts | DNS from the router does not apply while NordVPN carries DNS. NordVPN's own options (Threat Protection Lite, custom DNS) could do it but that is a VPN setting, and the owner asked for no DNS-filter plan unless raised | Owner raises it |
| U9 | Widevine level on an unofficial OS for this model | Per build, not checked | Only matters if tier 3 is chosen |
| U10 | Whether the eMMC test-point (FT232H) route unlocks sheldon on firmware past 7.2.7.3 | No source found says it beats the preloader patch; needs opening the stick, soldering and a computer | Out of this project's scope unless the owner raises it |
| U11 | What `com.firesend.cleaner` does (a background cleaner could overlap with or replace stage D) | Not researched yet | Owner says how they use it, or I look it up before stage D |
| U12 | What `dev.app1.xyz` is | Package name says nothing | Owner says what it is; it is never touched either way |
| U13 | Runtime state of `com.amazon.tv.launcher/.ui.HomeActivity_vNext` (0.7 printed the manifest's `enabled=false`) | Escape hatch matters; the resolver still returns it | Read-only: `dumpsys package com.amazon.tv.launcher \| grep -A3 -i disabledComponents`, plus you confirming long-press Home opens the stock launcher |
| U14 | The one system package lost when the 0.5 list was relayed (236 of 237); likely `com.amazon.device.services` (INFERENCE: it runs in 0.8 but is not in the list) | Relay gap | Batch 0.5c |
| U15 | The 35 packages in the gap analysis's Unresolved category (including the `dummy.*` stubs and `providers.contentsupport`) | No Fire TV evidence for their role or for disabling them | One `dumpsys package` look each, on request |
| U16 | ~~Whether atvTools accepts lines near 680 characters~~ | Resolved: CHECK (about 680) ran to completion | Done |
| U17 | What `com.amazon.adep` actually does. The relayed note called it blacklist enforcement; this repo's Fire OS 8 list calls it package verification and security events; no source confirms either | Unverified | Stage C0 |
