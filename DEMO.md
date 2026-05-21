# richardbot-template — live demo script

Runbook for kicking the tires in front of an audience. Eight acts, ~15 minutes total. Each act:

- **Setup** — what to have on screen before you talk
- **Say** — the one-line frame
- **Run** — exact commands
- **Watch for** — the moment the audience should notice
- **Tire-kick** — where this honestly breaks down

Lightning version: do Acts 1, 4, 5 only (5 minutes). Deep version: add Act 9.

---

## Act 1 — The problem (1 min)

**Setup.** Open a fresh terminal in a real client repo. Have CLAUDE.md from a competitor visible in another tab — the 370-line monolithic one.

**Say.** *"Today's AI tools either get a wall-of-rules dumped in every conversation, or they get nothing. Both fail: the wall blows your context window in two turns; nothing means the AI greps the same 80,000-line codebase every time. We need a third thing: lazy-loaded, trigger-fired context that's there when relevant and silent when not."*

**Run.** Show the 370-line monolithic CLAUDE.md scrolling. Then:

```bash
wc -l /path/to/competitor-CLAUDE.md
# ~370 lines, ~24 KB
```

**Watch for.** The audience sees a single file. That's the strawman.

---

## Act 2 — Install (1 min)

**Setup.** A *different* fresh repo with no `.claude/`, no `.richardbot-memory/`, no `.github/copilot-instructions.md`.

**Say.** *"One command, no config required."*

**Run.**

```bash
cd /path/to/some-clean-repo
richardbot-init init
ls .claude/ .richardbot-memory/ .github/
```

**Watch for.** Three new directories. `.claude/rules/`, `.claude/hooks/`, `.claude/commands/`, `.richardbot-memory/`, `.github/copilot-instructions.md`. Note: rules are tiny fragments (≤80 lines each), not a wall.

```bash
ls -la .claude/rules/
wc -l .claude/rules/*.md | tail -1
# something like 600 lines total, split across 15 files
```

**Tire-kick.** *"Yes, the total bytes are similar to the monolithic file. The win isn't bytes — it's that only the 3-5 relevant fragments fire on any given prompt. The other 10 stay quiet."*

---

## Act 3 — Survey: read the repo (1 min)

**Setup.** Still in the clean repo.

**Say.** *"It read your repo. It knows which surfaces exist."*

**Run.**

```bash
richardbot-init survey
```

**Watch for.** Output names the surfaces it detected (cart, product, checkout, etc.) and which rule fragments cover them. Then:

```bash
cat .claude/rules/surface-vue-components-cart.md | head -20
```

**Tire-kick.** *"Survey is heuristic — it pattern-matches dir names. For a stack it doesn't recognize, you'd run `richardbot-init pack add <stack>` for one of the canned packs, or write fragments yourself."*

---

## Act 4 — The killer demo: AI already knows the bug (2 min)

**Setup.** Open a Copilot chat (or Claude Code CLI) in a repo that has richardbot installed AND has memory notes under `.richardbot-memory/`.

**Say.** *"Watch what happens when I ask a question the AI's been told the answer to."*

**Run.** In Copilot chat:

```
is there an XSS risk in the cart components
```

**Watch for.** The AI should answer **from memory** — citing `CartFooter.vue:10` and `CartShippingThreshold.vue:8` — without invoking grep or file-read tools first. That's the proof: the memory note `.richardbot-memory/cart-bugs-discovered-on-install-2026-05-14.md` was always-loaded into Copilot's context via the `.github/copilot-instructions.md` mirror.

**Tire-kick.** *"It only works because we already scanned cart and planted the note. For unscanned surfaces, the AI falls back to exploration. That's why Act 5 exists."*

---

## Act 5 — How the notes get planted (3 min)

**Setup.** Same repo. Pick a surface that hasn't been scanned yet.

**Say.** *"You don't write the bug notes by hand. The template runs a Haiku subprocess to scan each surface and dump findings. Haiku is one twentieth the cost of Opus; for code-quality scans it's the right model."*

**Run.**

```bash
time richardbot-init seed src/vue/components/wishlist haiku
```

While it runs, narrate:

- `claude --print --model haiku --output-format json --max-turns 15`
- One-shot subprocess; clean context; writes to `.richardbot-memory/`
- Cost on stdout via `total_cost_usd` from the JSON envelope

**Watch for.** Wall time ~30-90s, cost ~$0.10. New file at `.richardbot-memory/wishlist-bugs-...md` with file:line findings.

```bash
ls -lt .richardbot-memory/ | head -3
cat .richardbot-memory/wishlist-bugs-*.md | head -30
```

**Tire-kick.** *"Haiku misses subtle stuff. For surfaces where correctness matters more than coverage (auth, payment), use sonnet — 4x the cost, much cleaner schema. We can also re-run on a fixed file: `richardbot-init seed src/auth sonnet`."*

---

## Act 5b — Periodic refresh: `rescan` (1 min)

**Setup.** Same repo, with at least one `.richardbot-memory/*-bugs-*.md` already present from Act 5 or a prior pass.

**Say.** *"Codebases change. Bug notes go stale. The `rescan` command refreshes them — by surface, by git-changed-recency, or wholesale."*

**Run.**

```bash
# Single surface, fast
richardbot-init rescan --surface src/vue/components/cart --model haiku

# Weekly cron mode: only rescan surfaces touched in the last 7 days
richardbot-init rescan --since "7 days ago"

# Age out anything older than 30 days as a hygiene pass
richardbot-init rescan --age-out 30 --no-mirror
```

**Watch for.** Prior date-stamped memos move into `.richardbot-memory/.archive/` instead of being overwritten — the audit trail survives. `copilot-mirror` runs automatically at the end so Copilot's view stays in sync.

**Tire-kick.** *"Rescan is `--print --model haiku` under the hood. It's deterministic-ish but not perfectly stable run-to-run; if a finding disappears between rescans, check the archive before assuming the bug was fixed. And the `--since` filter is git-only — for repos without git history, fall back to `--surface`."*

For ongoing operation, wire it into GitHub Actions:

```yaml
# .github/workflows/richardbot-rescan.yml (paste into your repo)
on:
  schedule: [{cron: '0 12 * * 1'}]  # Mondays 12:00 UTC
jobs:
  rescan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: {fetch-depth: 0}
      - run: bin/richardbot-init rescan --since "7 days ago"
      - uses: peter-evans/create-pull-request@v6
        with: {title: "chore: weekly bug-rescan", branch: "richardbot/rescan-weekly"}
```

---

## Act 6 — The Copilot mirror (1 min)

**Setup.** Show `.github/copilot-instructions.md` is auto-generated.

**Say.** *"Same rule corpus, different consumers. Claude Code reads `.claude/rules/`. GitHub Copilot reads `.github/copilot-instructions.md` + `.github/instructions/*.instructions.md`. Both are mirrored from one source."*

**Run.**

```bash
richardbot-init copilot-mirror
ls .github/instructions/ | head -10
head -30 .github/copilot-instructions.md
```

**Watch for.** One source-of-truth, two consumers. Each `applyTo:` glob in `.github/instructions/` targets a specific surface — Copilot loads the right fragment when you're editing in that dir.

**Tire-kick.** *"Copilot's `applyTo` is glob-only; it doesn't have prompt-keyword triggers like our hook. So 'prompt-only' fragments get folded into the always-loaded file, which is slightly wasteful for Copilot context."*

---

## Act 7 — Packs: opinionated stacks (1 min)

**Setup.** A repo where richardbot is installed but no packs yet.

**Say.** *"Some teams want everything pre-decided. We ship `shopify-theme`, `nextjs-app`, others. Each is 10-15 fragments tuned to the stack's failure modes."*

**Run.**

```bash
richardbot-init pack list
richardbot-init pack add shopify-theme
ls .claude/rules/
# 15 new fragments: liquid-conventions, vue3-deprecations, etc.
```

**Watch for.** New rule fragments matching the stack. Each was derived from a real JIRA bug-review criterion the team already uses.

**Tire-kick.** *"Packs are opinionated. If your team has different conventions, fork the pack — they're just markdown."*

---

## Act 8 — Cost math (1 min)

**Setup.** Have a terminal ready to show real numbers.

**Say.** *"Three models, three jobs. Don't pay Opus rates for Haiku work."*

**Run.** Show the model-routing table from one of the rule fragments or just narrate:

- **Haiku** (~$0.05 startup tax + cheap): code scans, doc passes, triage lists
- **Sonnet** (~$0.20 startup tax + 4x rate): tests, dev work, PR-grade reviews
- **Opus** (~$1+ startup tax + 20x rate): architect, postmortem, hard design

Real numbers from a typical install pass:

- 15 surfaces × haiku scan = ~$2 total
- 1 architect verdict = ~$0.50
- Whole install: ~$2.50

**Watch for.** The cost slide is the closer for skeptics. AI tools that pay-Opus-for-everything are 20x more expensive than they need to be.

**Tire-kick.** *"Startup tax is real. A haiku subprocess pays ~$0.05 just to load CLAUDE.md and hooks. If the work is under that, in-context Skill is cheaper. We have a rule for picking the right lane."*

---

## Act 9 — Where it doesn't work (deep version, 2 min)

**Say.** *"Let me show you something that doesn't work yet. Honest demos beat polished demos."*

**Run.**

1. **VS Code Claude Code extension in a remote codespace** — hooks don't fire there. Fix: use the CLI in the codespace terminal, or rely on the Copilot mirror.

2. **Cross-repo memory** — a memory note in repo A doesn't surface in repo B even if the bug is the same. Each repo's `.richardbot-memory/` is local.

3. **Stale findings deduplication** — `rescan` archives prior memos but doesn't merge/diff. If you fix CartFooter.vue:10 between rescans, the new memo just won't include that line — but the AI doesn't see a "this was fixed last week" signal. Diff-tracking against the archive is a follow-up.

**Tire-kick.** Be specific about what's *not* fixed. The audience trusts the demo more after they see you admit limits.

---

## Closing question for the audience

*"What's the one rule in your team's code review that gets ignored every time, that you'd want baked into every AI conversation in your repo?"*

Their answer is the seed for their first custom rule fragment.

---

## Recovery moves if something breaks live

- **Loader returns empty.** Run `echo '{"prompt":"XSS"}' | bash .claude/hooks/prompt-fragment-loader.sh` and show the JSON output. The loader works in isolation; the issue is Claude Code didn't call it. Pivot to the CLI version.
- **Seed subprocess hangs.** Cap `--max-turns 10` and re-run. Haiku occasionally goes in circles on large dirs; sonnet's more stable.
- **Copilot ignores the mirror.** Start a *fresh* Copilot chat — existing sessions cache instructions.
- **gh auth fails on push.** `GH_TOKEN=$(gh auth token -u <account>) git push ...` with token-in-URL.

---

## Acts → time budget

| Tier | Acts | Time |
|---|---|---|
| Lightning | 1, 4, 5 | 5 min |
| Standard | 1-8 | 15 min |
| Deep | 1-9 + Q&A | 25 min |
