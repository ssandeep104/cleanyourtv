# Audit log (AUDIT: pasted from the owner's stick)

Raw findings per batch, kept short. The gap analysis (`01-gap-analysis.md`) is written from this once
batch 0.9 is in.

## 0.1 Device identity

AFTSS (Fire TV Stick Lite 2020), `sheldon`, `mt8695`, Fire OS 7.7.1.7 (PS7717/5741, `PS7717.5741N`),
Android 9 / SDK 28, security patch 2026-03-01, verified boot `green`. Verdict in [ceiling.md](ceiling.md).

## 0.2 Memory and storage

- RAM: 922,268 kB total, 157,924 kB available (about 17%). Tight for a 1 GB stick.
- `/data`: 4.9 GB, 2.4 GB free.

Biggest processes at the time (PSS), grouped:

| Group | Processes | PSS |
|---|---|---|
| YouTube, open in front at the time (DIRECT) | `com.amazon.firetv.youtube` 106 MB | 106 MB |
| Netflix, no activity listed (not on screen) | `com.netflix.ninja` 81 MB | 81 MB |
| Your always-on apps (keep) | `com.nordvpn.android` 104 MB, `com.conreo.couchytv` 28 MB, `io.github.toolicious.homeonfire` 18 MB | 150 MB |
| Prime Video | `com.amazon.firebat` 97 MB | 97 MB |
| Alexa and its media stack | `com.amazon.aca` 39 MB, `com.amazon.vizzini` 23 MB, `com.amazon.alexamediaplayer.runtime.ftv` (+`:smbs`) 21 MB, `com.amazon.whad` 7 MB, `com.amazon.tcomm` 6 MB | 96 MB |
| Stock launcher (escape hatch, keep) | `com.amazon.tv.launcher` 36 MB | 36 MB |
| Amazon background services seen running | `device.services`, `whisperlink.core.android`, `imp`, `device.software.ota`, `device.messaging`, `whisperjoin.middleware.np`, `systemnotices`, `connectivitycontroller`, `identity.auth.device.authorization`, `device.rdmapplication`, `neo.minerva`, `accessoryconfigservice`, `device.blepa` | about 70 MB |
| atvTools' own helper (needed while you work) | `dev.vodik7.atvtoolsserver` and `:i` | 11 MB |

What it already shows (INFERENCE, to confirm against 0.4 to 0.9):

- YouTube's 106 MB is the open app (DIRECT: it was reopened and paused when 0.2 ran). 0.2 is **not**
  evidence that YouTube lingers after you leave it. That needs a post-exit measurement, taken in the
  lifecycle stage (see [lifecycle.md](lifecycle.md), "Baseline measurement").
- Netflix was resident with no `/ activities` tag, so its process stayed in memory without a screen.
  That alone does not show it was doing work: Android keeps cached processes until it needs the RAM.
  Same baseline measurement applies.
- Prime Video (`firebat`) is running although it is not on the keep list. Question for the owner.
- Alexa is about 96 MB. Whether voice search is used decides that group. Question for the owner.
- `com.amazon.device.software.ota` is alive, so update machinery is active on this build.
- `com.amazon.neo.minerva` (telemetry) is running; it was disabled successfully on the same build in
  `examples/amazon-fire-tv-stick-lite-2020/` (DOCUMENT).
- Not candidates, whatever they look like: `com.amazon.device.blepa` and `com.amazon.accessoryconfigservice`
  (remote and Bluetooth pairing; INFERENCE from the names, kept out regardless), `com.amazon.tv.ime` (keyboard), `com.amazon.identity.auth.device.authorization`
  (Amazon sign-in that apps rely on), `com.android.*` system processes.

## 0.3 Backup

First run (AUDIT): only `getprop.txt` was real; the seven `pm` and `settings` files held
`cmd: Failure calling service package: Failed transaction (2147483646)` (confirmed word for word with `cat`).
Discriminator (AUDIT): `pm list packages -3` printed to the terminal works perfectly, so the failure is only
in redirecting `pm`/`settings` output straight to a file. Redesigned 0.3 (pipe through `cat`) is committed;
**its run is pending**.

## 0.4 Third-party apps (AUDIT, from the discriminator run)

18 packages. None of them goes into a change batch: third-party apps are yours, and the plan only touches
Amazon packages.

| Package | What it is | Status |
|---|---|---|
| `com.conreo.couchytv` | Couchy launcher | Off limits (DIRECT) |
| `io.github.toolicious.homeonfire` | Home On Fire | Off limits (DIRECT) |
| `com.stremio.one` | Stremio | Keep (DIRECT) |
| `com.amazon.firetv.youtube` | YouTube for Fire TV (confirms the name in lifecycle.md) | Keep (DIRECT) |
| `com.esaba.downloader` | Downloader | Keep (DIRECT) |
| `com.netflix.ninja` | Netflix | Keep (DIRECT) |
| `com.instagram.airwave` | Instagram for TV | Keep (DIRECT) |
| `com.nordvpn.android` | NordVPN | Keep (DIRECT) |
| `dev.vodik7.atvtoolsserver` | atvTools' helper on the stick: your only shell | Keep, never touch (INFERENCE: needed for every batch) |
| `org.videolan.vlc` | VLC | Yours, not in the brief: kept |
| `link.unlinked` | Unlinked (app store) | Yours, not in the brief: kept |
| `com.streamdev.aiostreamer` | AIO Streamer | Yours, not in the brief: kept |
| `com.amhkor.voltratv` | VoltraTV | Yours, not in the brief: kept |
| `com.firesend.cleaner` | FireSend Cleaner | Yours, not in the brief: kept. May overlap with the lifecycle stage (U11) |
| `dev.app1.xyz` | Unknown from the name | Yours: kept. UNRESOLVED (U12) |
| `com.amazon.tv.legal.notices.overlay.localisation.common` | Amazon resource overlay (legal notices) | Not a candidate: overlays for Settings screens, near the protected list |
| `com.amazon.tv.settings.v2.overlay.localisation.common` | Amazon resource overlay (Settings) | Not a candidate: Settings |
| `com.amazon.tv.parentalcontrols.overlay.localisation.common` | Amazon resource overlay (parental controls) | Not a candidate: leave alone |

Silk is not in this list, so it is a system package (`com.amazon.cloud9`, INFERENCE, checked in 0.5).
Note for the plan: `examples/amazon-fire-tv-stick-lite-2020/` disables Silk; you keep it, so that line is
not copied.
