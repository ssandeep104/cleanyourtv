# Current state and gap analysis

Built from the audit (AUDIT, batches 0.1 to 0.9, see [audit-log.md](audit-log.md)) and this repo's list for the
same model and build (DOCUMENT, `examples/amazon-fire-tv-stick-lite-2020/`: AFTSS, Fire OS 7.7.1.7, PS7717/5741,
applied and rebooted with Home, Prime Video and Netflix working). Every Amazon and Fire OS package in
[audit-0.5-system-packages.txt](audit-0.5-system-packages.txt) is in exactly one category below.

## Where the stick stands

- Fire TV Stick Lite (AFTSS, `sheldon`), Fire OS 7.7.1.7, Android 9. Shell-only: no unlock or exploit
  applies ([ceiling.md](ceiling.md)).
- 922 MB RAM with about 158 MB available; 2.4 GB free storage.
- 237 system packages (236 relayed, one still to locate with 0.5c), 18 third-party.
- Your earlier work left 9 packages disabled and none uninstalled for user 0.
- Couchy is Home through Home On Fire's accessibility service; the stock launcher is still the registered
  Home underneath (escape hatch intact).
- Update machinery is complete and enabled: `com.amazon.device.software.ota`, `.ota.override`,
  `com.amazon.tv.forcedotaupdater.v2` (all `enabled=0`, meaning default state, which is on). The OTA
  service is resident in every snapshot.
- Package verifier is on (`package_verifier_enable=1`); sideloading is allowed.

## The gap: Amazon presence still active

| Kind | Still active | Plan stage |
|---|---|---|
| Telemetry, metrics, logging, usage reporting | 14 packages | B1, B2 (plus 8 protected, which stay) |
| Ads, sponsored rows, promos, notices, Live tab | 8 packages | B3 |
| Setup and provisioning helpers for other Amazon devices | 4 packages | B4 |
| Alexa extras (voice search works without them on this build) | 10 packages | B5, B6 |
| Preloaded Amazon apps and tutorials | 8 packages (4 of them already disabled by you) | A |
| Update machinery | 3 packages | C1 (attempt) |
| App verification and enforcement | 2 packages + 1 setting | C0 (read-only), then a decision |
| Prime Video | 2 packages | Your answer to Q1 |
| Alexa voice core | 9 packages | Your answer to Q2 |
| Amazon Appstore | 2 packages | Your answer to Q3 |

Resident processes this removes (AUDIT 0.8, RSS, which double-counts shared memory): roughly
`ffsprovisioneeclient` 90 MB and `easyupgrade` 86 MB when they wake, `alexamediaplayer` 32 to 40 MB,
`whisperjoin.middleware.np` 23 MB, `systemnotices` 18 MB, `whad` 18 MB, `aca` (when running), `neo.minerva`
plus `.logcat` 6 MB, `developer.dataservice` 2 MB.

## Every Amazon and Fire OS package, by category

### Off limits (DIRECT) (2)

The stock launcher (escape hatch) and its Home fallback starter.

`com.amazon.tv.launcher`, `com.amazon.firehomestarter`

### Needed for the system to work: never in a batch (58)

Home handling, Settings and quick settings, setup/factory reset, HDMI-CEC and display, remote, Bluetooth and pairing, Wi-Fi and captive portal, keyboard, storage, time zone, Amazon account and sign-in, push messaging apps use, profiles and parental controls, accessibility, WebView, and their libraries. Some are here because their role touches these even if their name sounds optional.

`amazon.fireos`, `amazon.jackson19`, `android.amazon.perm`, `com.amazon.android.devicemodelinfo.resources`, `com.amazon.tv.sysappsinternal.resources`, `com.amazon.dcp`, `com.amazon.dcp.contracts.library`, `com.amazon.dcp.contracts.framework.library`, `com.amazon.identity.auth.device.authorization`, `com.amazon.device.settings`, `com.amazon.device.settings.sdk.internal.library`, `com.amazon.tv.settings.core`, `com.amazon.tv.settings.v2`, `com.amazon.tv.quicksettings.ui`, `com.amazon.tv.quicksettings.ui.sheldon.overlay`, `com.amazon.tv.oobe`, `com.amazon.tv.ooberesource`, `com.amazon.tv.legal.notices`, `com.amazon.tv.legalresources`, `com.amazon.tv.intentsupport`, `com.amazon.tv.keypolicymanager`, `com.amazon.tv.routing`, `com.amazon.uxcontrollerservice`, `com.amazon.fireinputdevices`, `com.amazon.device.blepa`, `com.amazon.device.bluetoothpa`, `com.amazon.device.bluetoothkeymaplib`, `com.amazon.autopairservice`, `com.amazon.accessoryconfigservice`, `com.amazon.connectivitycontroller`, `com.amazon.net.smartconnect`, `com.amazon.connectivitydiag`, `com.amazon.tv.devicecontrol`, `com.amazon.tv.devicecontrolsettings`, `com.amazon.tv.resolutioncycler`, `com.amazon.avsyncslider`, `com.amazon.tv.ime`, `com.amazon.webview.chromium`, `com.amazon.storage.manager`, `com.amazon.device.lowstoragemanager`, `com.amazon.providers.tv`, `com.amazon.tifobserver`, `com.amazon.ssm`, `com.amazon.ssmsys`, `com.amazon.kindleautomatictimezone`, `com.amazon.fireos.rescuepartycloud`, `com.amazon.prism.android.service`, `com.amazon.ftv.profilepicker`, `com.amazon.ftv.xpicker`, `com.amazon.tv.parentalcontrols`, `com.amazon.tv.turnstile`, `com.amazon.tv.consents`, `com.amazon.tv.notificationcenter`, `com.amazon.logan`, `com.amazon.application.compatibility.enforcer.sdk.library`, `com.amazon.device.messaging`, `com.amazon.device.messaging.sdk.library`, `com.amazon.device.messaging.sdk.internal.library`

### Kept for your apps and features (21)

Silk and its website launcher; casting and DIAL (phone to YouTube or Netflix); Matter casting; `imp` (black Home risk, see audit-log 0.6); in-app purchase and app sign-in support; text to speech; the screensaver package (turning it off is a menu setting). `tcomm` also backs voice.

`com.amazon.cloud9`, `com.amazon.tv.website_launcher`, `com.amazon.cast.sink`, `com.amazon.dialservice`, `com.amazon.awvflingreceiver`, `com.amazon.whisperlink.core.android`, `com.amazon.whisperplay.contracts`, `com.amazon.whisperplay.service.install`, `com.amazon.communication.discovery`, `com.amazon.tcomm`, `com.amazon.tcomm.client`, `com.amazon.tcomm.jackson`, `com.amazon.tv.matter`, `com.amazon.imp`, `com.amazon.android.marketplace`, `com.amazon.appaccesskeyprovider`, `com.amazon.tv.ottssocompanionapp`, `com.ivona.tts.oem`, `com.ivona.orchestrator`, `com.svox.pico`, `com.amazon.ftv.screensaver`

### Already disabled by you, left as they are (5)

Fire TV Channels, recommendations, two shopping packages, NFC. The other four you disabled are apps and move to stage A.

`com.amazon.hedwig`, `com.amazon.media.recommendations`, `com.amazon.shoptv.client`, `com.amazon.shoptv.firetv.client`, `com.android.nfc`

### Stage A: uninstall for user 0 (apps) (8)

User-facing Amazon apps and tutorials, all disabled without trouble on the same build. Four of these you had already disabled.

`com.amazon.tmm.tutorial`, `com.amazon.storm.lightning.tutorial`, `com.amazon.bueller.photos`, `com.amazon.gamehub`, `com.amazon.bueller.music`, `com.amazon.tahoe`, `com.amazon.ods.kindleconnect`, `com.amazon.minitv.android.app`

### Stage B1: disable (metrics and performance collection) (7)

All disabled on the same build.

`com.amazon.client.metrics.api`, `com.amazon.neo.minerva`, `com.amazon.neo.minerva.logcat`, `com.amazon.tv.fw.metrics`, `com.amazon.wirelessmetrics.service`, `com.amazon.perfcollection`, `com.amazon.perfc`

### Stage B2: disable (logging, data services, ACR, Wi-Fi password upload) (7)

All disabled on the same build. `wifilocker` uploads saved Wi-Fi passwords to Amazon.

`com.amazon.dp.logger`, `com.amazon.ceviche`, `com.amazon.tv.developer.dataservice`, `com.amazon.livedeviceservice`, `com.amazon.privacypassservice`, `com.amazon.wifilocker`, `com.amazon.tv.acr`

### Stage B3: disable (ads, promos, notices, Live tab) (8)

All disabled on the same build; Home, Prime Video and Netflix worked after a reboot.

`com.amazon.kso.blackbird`, `com.amazon.sneakpeek`, `com.amazon.hybridadidservice`, `com.amazon.tv.easyupgrade`, `com.amazon.systemnotices`, `com.amazon.uxnotification`, `com.amazon.franktvinput`, `com.amazon.tv.livetv`

### Stage B4: disable (setup helpers for other Amazon devices, Matter controller) (4)

All disabled on the same build.

`com.amazon.whisperjoin.middleware.np`, `com.amazon.tv.ffsprovisioneeclient`, `com.amazon.tv.mattercohost`, `com.amazon.naatyam`

### Stage B5: disable (Alexa alerts and media playback) (5)

Disabled on the same build with voice search still working.

`com.amazon.tv.alexaalerts`, `com.amazon.tv.alexanotifications`, `com.amazon.alexa.externalmediaplayer.fireos`, `com.amazon.alexamediaplayer.runtime.ftv`, `com.amazon.aiondec`

### Stage B6: disable (Alexa multi-room audio, hints) (5)

Disabled on the same build with voice search still working.

`com.amazon.audiohome`, `com.amazon.whad`, `com.amazon.whasettings`, `com.amazon.wha.mediabrowserservice`, `com.amazon.aca`

### Stage C1: attempt to disable (updates) (3)

`forcedotaupdater.v2` was disabled on a Fire OS 7 Amazon TV (`examples/amazon-fire-tv-afteu014/`); `ota` and `.ota.override` were refused there as protected. A refusal changes nothing, so the attempt itself is safe; what it does if accepted is checked in C1.

`com.amazon.tv.forcedotaupdater.v2`, `com.amazon.device.software.ota.override`, `com.amazon.device.software.ota`

### Stage C0: inspect read-only first, no change yet (2)

Their names point at app verification and enforcement. Community guides disable `application.compatibility.enforcer`; none documents what breaks. `adep` was looked at and left alone on a Fire OS 8 stick in this repo. Decided after C0.

`com.amazon.adep`, `com.amazon.application.compatibility.enforcer`

### Waits for your answer to Q1 (Prime Video) (2)

`firebat` is Prime Video; `tv.support` belongs to it on the same-build list.

`com.amazon.firebat`, `com.amazon.tv.support`

### Waits for your answer to Q2 (Alexa voice) (9)

Voice search core and its helpers. Even if you drop voice, `vizzini` came back at every boot on other Fire builds, so this needs its own research before any batch.

`com.amazon.vizzini`, `com.amazon.vizzini.ftvcds`, `com.amazon.aria`, `com.amazon.cardinal`, `com.amazon.alexa.datastore.app`, `com.amazon.alexadirectivebrokerservice`, `com.amazon.firetv.androidskillconnectioncapability`, `com.amazon.spotify.mediabrowserservice`, `com.amazon.comms.starktachyon`

### Waits for your answer to Q3 (Amazon Appstore) (2)

Appstore and its UI.

`com.amazon.venezia`, `com.amazon.tigris`

### Protected: Fire OS refuses to disable them, so not in any batch (8)

From the same-build list and other Fire OS 7 lists in this repo. They keep running; nothing in the shell stops them.

`com.amazon.device.crashmanager`, `com.amazon.device.logmanager`, `com.amazon.diode`, `com.fireos.usagestats.proxy`, `com.amazon.device.metrics`, `com.amazon.ftvads.deeplinking`, `com.amazon.tv.csapp`, `com.amazon.securitysyncclient`

### Unresolved: role unclear or no Fire TV evidence, kept out of every batch (35)

Includes the `dummy.*` stub packages: small, harmless placeholders that other apps may resolve intents to; no Fire TV report shows them disabled safely, so they stay. Also `providers.contentsupport`, which the same-build list disables but another Fire OS 7 list says also switches the text-to-speech engine.

`com.amazon.ale`, `com.amazon.alta.h2clientservice`, `com.amazon.avls.experience`, `com.amazon.csm.htmlruntime`, `com.amazon.d3`, `com.amazon.device.details`, `com.amazon.device.rdmapplication`, `com.amazon.device.sync`, `com.amazon.device.sync.sdk.internal`, `com.amazon.device_remote_config_sync_service`, `com.amazon.dpcclient`, `com.amazon.dummy.alarmclock`, `com.amazon.dummy.calendar`, `com.amazon.dummy.contacts`, `com.amazon.dummy.gallery`, `com.amazon.dummy.music`, `com.amazon.dummy.settings`, `com.amazon.firetv.troubleshooting`, `com.amazon.fireos.cirruscloud`, `com.amazon.katoch`, `com.amazon.cpl`, `com.amazon.neodelegate`, `com.amazon.neopactservice`, `com.amazon.platform.fdrw`, `com.amazon.recess`, `com.amazon.rtcsessioncontroller`, `com.amazon.sharingservice.android.client.proxy`, `com.amazon.spiderpork`, `com.amazon.stillwatching.activity`, `com.amazon.sync.provider.ipc`, `com.amazon.sync.service`, `com.amznfuse.operatorredirection`, `com.fireos.arcus.proxy`, `com.fireos.sdk.ftve.addp`, `com.amazon.providers.contentsupport`

### Android core packages

All `com.android.*`, `android`, `android.ext.*`: never touched. `com.android.nfc` was already disabled by you
and stays that way.

## What the plan cannot reach (shell-only ceiling)

- The 8 protected packages keep running and reporting.
- If C1 is refused, updates keep arriving, and an update can re-enable packages (re-run the stage checks
  after any update).
- Amazon's piracy blocklist is enforced against a list Amazon controls; no shell step is verified to stop it.
- The stock launcher's own sponsored feed remains, but you only see it through the escape hatch.
