# Quit on exit: what Fire OS allows

Goal (DIRECT): backing out of an app asks whether to quit; yes means fully quit. Leaving YouTube for
Stremio leaves no YouTube running. Must not break logins, casting or the launcher.

## The gap, plainly

**No system-wide "ask to quit on Back" exists on Fire OS, and none can be added from the shell.** Android
hands the Back key to the app in front; the system never sees "the user left the last screen" as an event
it can prompt on. A helper would need an accessibility service that watches every Back press and app
switch, then force-stops the app it left. No such app was found that is verified on Fire TV (UNRESOLVED,
see [unresolved.md](unresolved.md)). A second accessibility service alongside Home On Fire also risks
key handling conflicts with it.

So the target becomes: **an app you leave cannot keep doing work, and quitting fully is one press away.**

## Options evaluated

| Option | What it does | Verdict |
|---|---|---|
| Developer option "Don't keep activities" (`always_finish_activities`) | Destroys every screen you leave. The process stays cached anyway. | **Rejected.** It breaks flows that hop between screens: sign-in pages, the NordVPN "allow VPN" dialog, picking a file in Downloader, returning from Stremio's player. Does not stop background services. |
| "Background process limit" | Caps cached processes. | **Rejected.** Fire OS does not show it in its developer menu, there is no `settings` key for it, and it resets at each reboot. Can also kill NordVPN's helper processes (INFERENCE). |
| Per-app background restriction: `cmd appops set <pkg> RUN_ANY_IN_BACKGROUND ignore` | Once the app is not in front, Android stops its background services, jobs and alarms. Survives reboot. Undo: `... allow`. | **Recommended**, for the apps that should never work in the background (YouTube, Instagram, Netflix, Silk, Stremio). Needs SDK 28 or later (Fire OS 7+): checked against audit 0.1. Never applied to NordVPN, Couchy, Home On Fire, or any Amazon input, remote or Settings package. Logins are kept (they are stored data, not running processes). |
| `am kill <pkg>` | Kills an app's process only if it is in the background; safe, no data loss. | Useful as a manual "quit" from atvTools. |
| `am force-stop <pkg>` | Hard stop: process, services, alarms. Keeps data and logins. | The true "fully quit". Manual from atvTools, or from the Settings app page. Do not use it on Home On Fire: a force-stop switches its accessibility service off until you turn it on again. |

## Recommendation (stage D of the plan)

1. Apply `RUN_ANY_IN_BACKGROUND ignore` to the five apps above, using the exact package names from
   audit 0.4 (Fire TV's YouTube is usually `com.amazon.firetv.youtube`, INFERENCE, confirmed by the audit).
2. Keep one atvTools snippet per app: `am force-stop <pkg>`, as the "quit fully" button.
3. Check after: leave YouTube, open Stremio, then `ps -A | grep -i youtube` from atvTools should show
   at most a cached process doing nothing, and YouTube should still be signed in when reopened.

What stays open (the gap): no on-screen "Quit?" prompt when you press Back. A cached process may also stay
in memory until Android needs the RAM; it uses no CPU or network in that state.

Casting (INFERENCE, to test in stage D): casting from a phone to YouTube starts YouTube in front through
Amazon's DIAL service, so a background restriction should not block it. If casting stops working, the
restore line for YouTube undoes it in one command.
