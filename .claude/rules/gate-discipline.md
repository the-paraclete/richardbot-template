---
description: Dev-cycle gates (/review, /qa, /scan) surface ONLY FAIL/NEEDS-REVISION during the cycle. Polish, tooling-gripes, and already-solved-pattern observations HOLD for post-cycle bundle to PM.
triggers:
  prompt:
    - "/review"
    - "/qa"
    - "/scan"
    - "review gate"
    - "qa gate"
    - "scan friction"
    - "PASS FAIL NEEDS-REVISION"
    - "friction report"
    - "non-blocking"
    - "post-cycle"
    - "surface friction"
---

# Gate discipline

## The rule

Dev-cycle gates — `/review`, `/qa`, `/scan` — surface ONLY blocking
issues inline with the verdict. Non-blocking friction (polish, tooling
gripes, already-solved patterns observed in adjacent code,
missed-opportunity notes) is HELD for a post-cycle bundle to PM.

## What surfaces inline

- Anything that maps to **FAIL** — security failures, scope mismatches,
  design problems
- Anything that maps to **NEEDS-REVISION** — file:line blockers the
  dev must fix before merge
- Anything that **REQUIRED a workaround** to even produce the verdict —
  couldn't reach the surface, couldn't test without the workaround,
  etc. These get surfaced even on PASS because the workaround is itself
  a finding the next cycle should address.

## What holds for post-cycle

Held items go to a friction bundle the gate role writes to
`.richardbot-memory/friction-<date>.md` (or your team's equivalent
ticket-staging surface). Examples:

- Already-solved patterns observed in adjacent code that the dev
  didn't touch
- Polish suggestions ("this name could be clearer", "this could be
  DRY-er")
- Tooling gripes that don't block the merge
- Missed-opportunity observations ("while you were here, X could have
  been simplified")
- Anything that isn't actually gating the merge decision

## Why

Stopping the cycle to surface non-blocking friction trains the cycle
to SKIP the gate next time. The gate is a contract: PASS means
merge-stake; FAIL means send back. Adding "and also here are 5 polish
notes" bundles to every PASS verdict erodes the gate's signal-to-noise.

Operators learn fast that if `/review PASS` arrives with a paragraph
of polish notes appended, the rational move is to skim past the notes.
And once they're skipping the notes, they start skipping the verdict
too. The signal collapses.

Holding non-blocking friction for a separate post-cycle channel
preserves the gate's binary semantic.

## PM intake

Post-cycle, PM picks up the friction bundle from the staging surface
and triages it:

- File as tickets for follow-up cycles
- Merge into existing tickets for the same surface
- Drop the ones that turned out to be matter-of-taste rather than
  substantive
- Schedule the surviving ones into the next sprint's queue

Replace the staging-surface and PM-channel specifics with your team's
actual conventions — this rule names the SHAPE (separate bundle,
separate channel, PM as the triager), not the specific tooling.
