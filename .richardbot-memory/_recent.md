# `_recent.md` — append-only digest

One line per new memory. Newest on top. Format:

```
YYYY-MM-DD <type> <filename> — <one-line description>
```

Example:

```
2026-05-14 postmortem postmortem_cart_double_render_2026-05-14.md — root cause: cartStore mutation bypass; fix: guard mounted() against bfcache pageshow
```

(This file starts empty in a fresh template. Append as you plant.)
