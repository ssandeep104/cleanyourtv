# atvTools snippets

To be saved in atvTools on the phone (05-final-runbook.md, Section 2, checks which exist). Each is one line and safe to run any time.

| Name | What it does |
|---|---|
| Quit YouTube | Closes YouTube fully; keeps its sign-in |
| Quit Instagram | Closes Instagram fully; keeps its sign-in |
| Quit Stremio | Closes Stremio fully; keeps its sign-in |
| Bring Couchy back | After a drop-out (stock Home on screen, Home does nothing): starts Couchy so Home works again |

Quit YouTube:

```sh
am force-stop com.amazon.firetv.youtube; echo "stopped com.amazon.firetv.youtube"
```

Quit Instagram:

```sh
am force-stop com.instagram.airwave; echo "stopped com.instagram.airwave"
```

Quit Stremio:

```sh
am force-stop com.stremio.one; echo "stopped com.stremio.one"
```

Bring Couchy back:

```sh
monkey -p com.conreo.couchytv -c android.intent.category.LEANBACK_LAUNCHER 1 >/dev/null 2>&1; echo "couchy pid: $(pidof com.conreo.couchytv)"
```

Never make a quit snippet for Couchy, Home On Fire, NordVPN or atvTools' helper.
