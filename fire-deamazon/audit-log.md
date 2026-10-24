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
| Your apps left running in the background | `com.amazon.firetv.youtube` 106 MB, `com.netflix.ninja` 81 MB | 187 MB |
| Your always-on apps (keep) | `com.nordvpn.android` 104 MB, `com.conreo.couchytv` 28 MB, `io.github.toolicious.homeonfire` 18 MB | 150 MB |
| Prime Video | `com.amazon.firebat` 97 MB | 97 MB |
| Alexa and its media stack | `com.amazon.aca` 39 MB, `com.amazon.vizzini` 23 MB, `com.amazon.alexamediaplayer.runtime.ftv` (+`:smbs`) 21 MB, `com.amazon.whad` 7 MB, `com.amazon.tcomm` 6 MB | 96 MB |
| Stock launcher (escape hatch, keep) | `com.amazon.tv.launcher` 36 MB | 36 MB |
| Amazon background services seen running | `device.services`, `whisperlink.core.android`, `imp`, `device.software.ota`, `device.messaging`, `whisperjoin.middleware.np`, `systemnotices`, `connectivitycontroller`, `identity.auth.device.authorization`, `device.rdmapplication`, `neo.minerva`, `accessoryconfigservice`, `device.blepa` | about 70 MB |
| atvTools' own helper (needed while you work) | `dev.vodik7.atvtoolsserver` and `:i` | 11 MB |

What it already shows (INFERENCE, to confirm against 0.4 to 0.9):

- YouTube and Netflix stay resident after use: the lifecycle problem in [lifecycle.md](lifecycle.md) is real.
- Prime Video (`firebat`) is running although it is not on the keep list. Question for the owner.
- Alexa is about 96 MB. Whether voice search is used decides that group. Question for the owner.
- `com.amazon.device.software.ota` is alive, so update machinery is active on this build.
- `com.amazon.neo.minerva` (telemetry) is running; it was disabled successfully on the same build in
  `examples/amazon-fire-tv-stick-lite-2020/` (DOCUMENT).
- Not candidates, whatever they look like: `com.amazon.device.blepa` and `com.amazon.accessoryconfigservice`
  (remote and Bluetooth pairing; INFERENCE from the names, kept out regardless), `com.amazon.tv.ime` (keyboard), `com.amazon.identity.auth.device.authorization`
  (Amazon sign-in that apps rely on), `com.android.*` system processes.
