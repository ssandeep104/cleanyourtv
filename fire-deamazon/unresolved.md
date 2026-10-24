# Unresolved

Each item below is kept out of every batch until it is verified.

| # | Item | Why it is unresolved | What would resolve it |
|---|---|---|---|
| U1 | Model, codename, Fire OS build, SDK | Not supplied yet | Audit batch 0.1 |
| U2 | Which package enforces Amazon's app blacklist on Fire OS 7/8 | No source names it; reports say it matches package names against Amazon's cloud list. This repo's 4K 2023 list left `com.amazon.adep` (package verification) and `com.amazon.platform.fdra` (package allowlisting) alone. | Audit 0.9, then `dumpsys package` on each candidate; even then, disabling may be refused or may break installs |
| U3 | Whether the OTA packages can be disabled on this build | Protected on some Fire OS 7 builds (`afteu014`), not tried on others | Audit 0.9 shows them; a refused `pm disable-user` is a no-op, so the attempt itself is safe |
| U4 | Whether the system-user exploit (tier 2) applies | Depends on build: Fire OS 7 at PS7704 or older, Fire OS 8 at RS8149 or older | Audit 0.1 |
| U5 | A helper app for a "Quit?" prompt on Back | None found that is verified on Fire TV | Owner names one, or we accept the gap in [lifecycle.md](lifecycle.md) |
| U6 | Home On Fire internals (what it watches, whether a second accessibility service conflicts) | Project page not found in research | Owner shares its link or the app's about screen |
| U7 | Whether Stremio is on Amazon's blocklist | Not named in any report found, but the list is private | Watch for a block screen; no action possible from the shell |
| U8 | Network-level blocking of Amazon update and telemetry hosts | DNS from the router does not apply while NordVPN carries DNS. NordVPN's own options (Threat Protection Lite, custom DNS) could do it but that is a VPN setting, and the owner asked for no DNS-filter plan unless raised | Owner raises it |
| U9 | Widevine level on an unofficial OS for this model | Per build, not checked | Only matters if tier 3 is chosen |
