# The Ceiling — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the public companion repo for the RubyConf talk "The Ceiling: Why Ruby 4.0 Needed a Second Compiler": complete presentation (swim-story, beginner-friendly), runnable source + captures behind every slide, a formal YJIT vs ZJIT analysis, and annotated references.

**Architecture:** One Org file (`talk/the-ceiling.org`) is the presentation and the source of truth for the demo Ruby: named slide blocks are noweb-assembled and tangled into `src/`. Shell scripts in `bin/` run the captures into `captures/` (addresses stripped) and run `bin/check`, a set of integrity tests (every slide listing line exists in a capture, tangled files are current, no personal paths, export succeeds). Reveal.js HTML is exported by a batch-Emacs script that installs org-re-reveal into a git-ignored repo-local dir.

**Tech Stack:** Ruby 4.1.0-preview1 (asdf, built `--enable-yjit=dev --enable-zjit=dev`), activesupport 8.1.x, Org 9.7+/10, org-re-reveal (MELPA, repo-local), reveal.js 4.6.1 via jsDelivr CDN, POSIX sh + awk, xmllint, inline/standalone SVG.

**Spec:** `docs/design.md` (copied from `scratchpad/design/2026-11-14-the-ceiling-design.md` in Task 1). Executors read both.

## Global Constraints

- Repo: `~/src/dhruvasagar/the-ceiling/`; public on GitHub; **the speaker pushes** — never create a remote or push.
- Licences: MIT (`LICENSE`, code), CC BY 4.0 (`LICENSE-CONTENT`, prose/slides/diagrams).
- Ruby pinned in `.tool-versions`: `ruby 4.1.0-preview1`. Every slide showing compiler output carries the label "Ruby 4.1.0-preview1".
- Only four technical words on slides: **guard, profile, inlining, IR**. All other jargon lives in `#+begin_notes` or `analysis/`.
- Every slide pattern: swim diagram first, then a proof slide with 3–8 real lines, highlighted, one plain-English caption per side (YJIT left, ZJIT right).
- A listing line on a slide must exist in a file under `captures/` (after normalisation). A claim not backed by a capture cites a §9 source with a date.
- ZJIT goals may be used, always attributed + dated, presented as goals, never as current behaviour.
- Personal story beats are `[STORY: …]` placeholders with a suggested line; never invent biography. Speaker swims open water only (no triathlon). "Feed stops" is a general image, not his story. The 2-beat kick IS his practice.
- Takeaway sentence (verbatim): "YJIT compiles Ruby a bit at a time, deciding as it goes; ZJIT plans a whole method at once, so it can see through small method calls and stop paying for them. That's the room Ruby needed to keep getting faster."
- Talk: 20:00 total with ~1:00 slack; "One more call" and "Why ZJIT was built" are never cut.
- No absolute personal paths (`/Users/`, `/private/tmp`) in committed files; memory addresses stripped from published listings.
- Phase 1 (Tasks 1–6) must be complete by **2026-11-15**; Phase 2 (Tasks 7–10) by **2026-11-21**.

## Review Focus

1. **A reader without Emacs** clones the repo → `bin/capture` and `bin/check` run from plain sh and say clearly what's missing (wrong Ruby, no dev build, no activesupport) instead of producing empty captures. → test in Task 2 (`check_env` failure messages).
2. **Non-dev Ruby build** → `--yjit-dump-disasm` prints nothing/errors; capture must fail loudly, not write an empty file the slides silently pass against. → Task 2 asserts each capture file is non-empty and contains its marker.
3. **SSA value numbers shift between runs/versions** (`v95` today) → listing check must compare against the *same* checked-in capture, and slides must be regenerated together; Task 3 checks listings against `captures/`, not a fresh run.
4. **Stale wording after edits** ("parity in 4.1", "bike", "a draw", `[VERIFY`) reaching the projector → Task 5 grep test.
5. **Presenting from Emacs shows notes on the projector** → Task 6 README "Presenting" section + reveal export is the presenting path; Emacs only for the live block.

---

## File Structure

```
the-ceiling/
  README.md              what/why, reproduce, view the talk, present it
  LICENSE  LICENSE-CONTENT
  .tool-versions  .gitignore      (.gitignore: .emacs-deps/ talk/*.html~ )
  docs/design.md  docs/plan.md
  talk/the-ceiling.org   the presentation (slides + notes + noweb sources)
  talk/the-ceiling.html  committed reveal export
  talk/img/*.svg         swim diagrams (one per idea)
  src/*.rb               TANGLED from talk/the-ceiling.org — do not edit
  bin/capture            runs all captures → captures/
  bin/normalize          stdin→stdout: strip addresses/whitespace (shared by capture + check)
  bin/check              integrity tests (exit non-zero on any failure)
  bin/export             batch-Emacs reveal export (installs org-re-reveal to .emacs-deps/)
  bin/lib/check-listings.awk   listing-integrity check
  captures/*.txt         checked-in raw outputs
  analysis/yjit-vs-zjit.md
  references/README.md
```

---

## Phase 1 — draft due 2026-11-15

### Task 1: Scaffold the repo

**Files:** Create `README.md` (stub), `LICENSE`, `LICENSE-CONTENT`, `.tool-versions`, `.gitignore`, `docs/design.md`, `docs/plan.md`, `bin/check` (skeleton).

**Interfaces:** Produces `bin/check` — sh script; runs every `check_*` function defined in it in order; prints `ok <name>` / `FAIL <name>: <reason>`; exits 1 if any failed. Later tasks add `check_*` functions.

- [ ] **Step 1:** `mkdir -p ~/src/dhruvasagar/the-ceiling && cd $_ && git init -b main`.
- [ ] **Step 2: Write the failing check** `check_no_personal_paths`: `git ls-files -z | xargs -0 grep -lE '/Users/|/private/tmp' ` must print nothing (exclude `docs/`, where the spec mentions the roam path — strip that path from the copied spec instead).
- [ ] **Step 3:** Run `bin/check` → FAIL (spec copy contains `/private/tmp`).
- [ ] **Step 4:** Copy spec → `docs/design.md`, plan → `docs/plan.md`, replacing absolute paths with descriptive text. Write `.tool-versions` (`ruby 4.1.0-preview1`), licences, README stub (title, one-paragraph intent, "draft").
- [ ] **Step 5:** `bin/check` → `ok no_personal_paths`, exit 0.
- [ ] **Step 6: Commit** `chore: scaffold the-ceiling repo`.

### Task 2: Demo source + captures

**Files:** Create `talk/the-ceiling.org` (header + Demo/Files section only for now), `bin/normalize`, `bin/capture`, `captures/*.txt`. Modify `bin/check`.

**Interfaces:**
- Consumes: `bin/check` (Task 1).
- Produces:
  - Named noweb blocks in `talk/the-ceiling.org`: `point-class`, `distance-v1`, `distance-v2`, `warmup` (exact bodies from the roam note), tangled to `src/distance.rb`, `src/distance_sq.rb`, `src/hwia.rb`.
  - `bin/normalize` filter: removes `@0x[0-9a-f]+`, `, cme:0x[0-9a-f]+`, ` (0x[0-9a-f]+)`, leading/trailing spaces, collapses runs of spaces.
  - `bin/capture [name…]` writes, from `src/`: `yarv-distance.txt`, `yjit-distance.txt`, `zjit-distance.txt`, `yjit-sq.txt`, `zjit-sq.txt`, `hwia-source.txt`, `hwia-yjit-stats.txt`, `hwia-zjit-stats.txt`, `when-yjit.txt`, `when-zjit.txt`, `env.txt` (`ruby -v`, activesupport version). Commands exactly as the roam note's Captures (`--yjit-call-threshold=1 --yjit-dump-disasm`; `--zjit-call-threshold=2 --zjit-dump-hir`; `--yjit-stats`; `--zjit-stats`). **New "when" captures:** `when-yjit` = `ruby --yjit --yjit-call-threshold=1 --yjit-log=… src/distance.rb` (or `--yjit-dump-disasm` block headers in call order); `when-zjit` = `ruby --zjit --zjit-trace-compiles src/distance.rb` with the **default** threshold, plus a variant printing the call count at which `distance` compiled. Pick whichever flags actually show it on preview1 and record the command in the file's first line.
  - Each capture file's first line: `# $ <exact command>  (ruby <version>)`.
- Header args carried from the roam note: asdf shim prologue, `:ruby "$HOME/.asdf/shims/ruby"`, auto-tangle `:dir` expression with the `ceiling--tangling` guard — but `:dir` → `../src`.

- [ ] **Step 1: Write failing checks** in `bin/check`:
  - `check_env`: `ruby -v` (from repo root, via `.tool-versions`) contains `4.1.0preview1`; `ruby --yjit --yjit-dump-disasm -e 1` exits 0; `ruby -ractive_support -e 1` exits 0. Each failure prints the fix (e.g. "build Ruby with RUBY_CONFIGURE_OPTS='--enable-yjit=dev --enable-zjit=dev' asdf install ruby 4.1.0-preview1").
  - `check_tangle_current`: batch-Emacs `org-babel-tangle` of `talk/the-ceiling.org`, then `git diff --exit-code src/`.
  - `check_captures`: each file exists, is non-empty, and contains its marker: `zjit-sq.txt` ↦ `PushInlineFrame :sq`; `yjit-sq.txt` ↦ `call to Object#sq` AND `guard arg0 fixnum`; `yjit-distance.txt` ↦ `clear local variable types`; `zjit-distance.txt` ↦ regex `FixnumMult (v[0-9]+), \1`; `hwia-zjit-stats.txt` ↦ `Hash#[]`; `when-zjit.txt` ↦ `distance`.
- [ ] **Step 2:** `bin/check` → FAILs (no talk, no captures).
- [ ] **Step 3:** Write the org header + Demo section, `bin/normalize`, `bin/capture`. Tangle, run `bin/capture`.
- [ ] **Step 4:** `bin/check` → all ok.
- [ ] **Step 5: Commit** `feat: demo source and captures for distance, sq, hwia, when-it-compiles`.

### Task 3: Listing-integrity check

**Files:** Create `bin/lib/check-listings.awk`. Modify `bin/check`.

**Interfaces:**
- Consumes: `bin/normalize`, `captures/` (Task 2).
- Produces: `check_listings` — for every `#+begin_example` in `talk/the-ceiling.org` immediately preceded by a comment line `# capture: <file>[, <file>]`, every non-blank line (split side-by-side columns on 3+ spaces; ignore lines exactly `...`/` ...` and a first line that is only column headers `YJIT`/`ZJIT`) must, after `bin/normalize`, be a substring of some normalised line in one of the named capture files. Example blocks with no `# capture:` comment fail the check ("listing without a source").

- [ ] **Step 1: Write failing fixture tests** in `bin/check` (`check_listings_selftest`) using a temp org file: (a) a listing whose lines all exist in a temp capture → pass; (b) one invented line → fail naming the line; (c) a listing with no `# capture:` → fail.
- [ ] **Step 2:** Run → selftest FAILs (awk not written).
- [ ] **Step 3:** Write `check-listings.awk`.
- [ ] **Step 4:** Selftest ok; `check_listings` on the real talk ok (no listings yet = vacuously ok).
- [ ] **Step 5: Commit** `test: listing integrity check`.

### Task 4: Swim diagrams

**Files:** Create `talk/img/`: `head-up.svg` (beginner, head up every stroke), `sighting.svg` (look once, head down; off-course → stop & look), `buoy-to-buoy.svg` (YJIT), `course-map.svg` (ZJIT, beach + warm-up lap), `first-wave.svg` (wave mid-leg: YJIT head up again, ZJIT line holds), `turn-buoy.svg` (the approved mockup "A": YJIT 👀 at every buoy dashed, ZJIT one solid planned line), `two-beat-kick.svg` (kicks timed to the whole stroke cycle vs kick-by-kick), `fog-chop.svg`, `feed-stop.svg`. Modify `bin/check`.

**Interfaces:** Produces the SVG filenames above; Task 5 references them as `[[file:img/<name>.svg]]`.

Style: 16:9 viewBox `0 0 1600 900`, water `#e6f2fb`, YJIT `#c48a00` dashed, ZJIT `#2e8b3e` solid, buoys `#f08a24`, labels ≥ 36px, text in plain words only (no jargon beyond the four allowed), colour never the only signal (YJIT dashed + 👀 icon, ZJIT solid + 🗺 icon).

- [ ] **Step 1: Write failing check** `check_diagrams`: every `img/*.svg` referenced in the talk exists and `xmllint --noout` passes.
- [ ] **Step 2:** Run → FAIL once Task 5 references exist; for now add the references list to the check directly and see FAIL.
- [ ] **Step 3:** Draw the nine SVGs.
- [ ] **Step 4:** `check_diagrams` ok; open each in a browser and check legibility at projector size.
- [ ] **Step 5: Commit** `feat: swim diagrams`.

### Task 5: The presentation

**Files:** Modify `talk/the-ceiling.org` (slides + notes above the Demo section). Modify `bin/check`.

**Interfaces:** Consumes diagrams (Task 4), captures (Task 2), `check_listings` (Task 3).

Slides — exactly the spec §6 table, as level-1 headings with `:DURATION:` (times from the table), plus a `:noexport:` "Timing plan" table and a `:noexport:` "Demo"/"Captures" section (from Task 2). For each technical slide: diagram slide, then proof slide (`# capture: …` comment + `#+begin_example` trimmed 3–8 lines + caption line per side). Specifics:
- "Two JITs. Why?": `[STORY: first open-water swim, lifting head every stroke; coach: "every time you lift your head, you slow down."]`; the question; one bio line (15 years Ruby, writes Rust).
- "How Ruby runs your code": live block `ruby -r ./distance -e 'puts RubyVM::InstructionSequence.of(method(:distance)).disasm'` + fallback listing from `yarv-distance.txt`.
- "What a JIT does": introduces **guard**; no listing.
- "YJIT: buoy to buoy" + proof from `yjit-distance.txt` (the `# guard …` / `defer_compilation` lines). Add the **when** proof from `when-yjit.txt`.
- "ZJIT: study the course" + IR on one slide from `zjit-distance.txt` (~8 lines) + **when** proof from `when-zjit.txt`; introduces **profile**, **IR**; "Prove, don't guess."
- "Same five lines, a first wave" (replaces "Round 1: a draw").
- "One more call": `turn-buoy.svg` then side-by-side from `yjit-sq.txt` / `zjit-sq.txt` (the approved "B" lines); introduces **inlining**. Claim wording: "here, YJIT checked again" — not "always forgets".
- "Why ZJIT was built": `two-beat-kick.svg`; `[STORY: learning the 2-beat kick — couldn't get there by fixing each kick; it clicked when timed to the whole stroke]`; quote (Bernstein, 2025-12-24): "we want to both raise the performance ceiling (bigger compilation unit size and SSA IR) and encourage more outside contribution (by becoming a more traditional method compiler)." Goals (dated, attributed): general-purpose inliner "in the fullness of time" (2025-12-24); 4.1 NEWS method inlining incl. methods that yield; contribution-friendly "textbook" compiler (2025-05-14). Cost: time on the beach; 4.0 "not yet as fast as YJIT. Yet."
- "A method you already run": HWIA excerpt (from `hwia-source.txt`) + `Hash#[]` stat line; `feed-stop.svg`.
- "Where it gives up": `fog-chop.svg` + `feed-stop.svg`; proof listing deferred to Task 7 (slide says "stops guessing, swims head-up again"; until E4 lands, notes carry the preliminary numbers labelled preliminary).
- "What it means for Ruby": takeaway sentence verbatim; status quotes dated (4.0 notes; 2026-10-09 "now as fast as YJIT" on SFR in small regions; 4.1 NEWS caveat); three commands (`RubyVM::InstructionSequence…disasm`, `--zjit-dump-hir`, `--zjit-stats`); repo URL placeholder `[REPO-URL]`.
- Close: "Which part is slow?"
- Speaker notes: plain language, ≤ ~130 spoken words per minute of `:DURATION:`; depth (shapes, side exits, SSA, PatchPoint, CCallWithFrame) only in notes, each with a one-line plain explanation the speaker can say if asked.

- [ ] **Step 1: Write failing checks**:
  - `check_stale_wording`: talk contains none of `bike`, `triath`, `a draw`, `[VERIFY`, `parity in 4.1`, `forgets what it learned at every method call`.
  - `check_timing`: sum of `:DURATION:` values (exported slides) is between 18:30 and 20:00.
  - `check_jargon`: exported slide bodies (excluding notes, listings, and the `src` blocks) contain none of `SSA`, `side exit`, `PatchPoint`, `shape`, `Fixnum`, `basic block`.
  - `check_takeaway`: the verbatim takeaway sentence appears in the talk.
- [ ] **Step 2:** Run → FAILs.
- [ ] **Step 3:** Write the slides and notes.
- [ ] **Step 4:** `bin/check` all ok (including `check_listings` now with real listings).
- [ ] **Step 5: Commit** `feat: complete presentation draft`.

### Task 6: Export, minimal README, draft handoff

**Files:** Create `bin/export`, `talk/the-ceiling.html`. Modify `README.md`, `bin/check`, `.gitignore`.

**Interfaces:** `bin/export` — batch Emacs: `package-initialize` with `package-user-dir` = `.emacs-deps/`, install `org-re-reveal` from MELPA if missing, `REVEAL_ROOT` `https://cdn.jsdelivr.net/npm/reveal.js@4.6.1`, export `talk/the-ceiling.org` → `talk/the-ceiling.html`. Must not load the user's init.

- [ ] **Step 1: Write failing check** `check_export`: `bin/export` exits 0; HTML exists, newer than the .org, contains `reveal.js@4.6.1`, contains every slide heading, contains `class="notes"` (speaker notes present), contains no `#+begin_`.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Write `bin/export`; export. README: what this is, status "draft for RubyConf 2026-11-21, Ruby 4.1.0-preview1", how to view (`talk/the-ceiling.html`, press `s` for speaker view), how to reproduce (build Ruby, `gem install activesupport`, `bin/capture`, `bin/check`), **Presenting** (present the HTML; use Emacs only for the live block — org-tree-slide/org-present would show notes on the projector).
- [ ] **Step 4:** `bin/check` all ok. Open the HTML, step through every slide and the speaker view.
- [ ] **Step 5: Commit** `feat: reveal export and README — draft for submission`. **Phase 1 done: tell the speaker the draft is ready (path to HTML + org) and list every `[STORY: …]` placeholder for him to fill.**

## Phase 2 — by 2026-11-21

### Task 7: E4 "where it gives up"

**Files:** Create `src/chop.rb` (tangled from a new named block), captures `chop-zjit-stats.txt`, `chop-zjit-hir-before.txt`, `chop-zjit-hir-after.txt` (or equivalent), `chop-yjit-stats.txt`. Modify talk "Where it gives up" proof slide, `bin/check`.

Design: start from the preliminary `double(x) = x + x`, warm on Integers, then feed `[1, 2.5, "ab", [1], 3r]`. Goal: a capture that *visibly* shows specialised code being abandoned (e.g. `guard_type_failure` count + HIR before vs after recompile, or `--zjit-trace-exits`). If no clean visible give-up exists on preview1, the slide states exactly what the capture shows ("stops guessing, swims head-up again") with the numbers.

- [ ] **Step 1: Failing check** `check_captures` markers for the chosen files (marker = the specific counter/line the slide uses).
- [ ] **Step 2:** Run → FAIL. **Step 3:** Write program, capture, update slide (+ `# capture:`). **Step 4:** `bin/check` ok, re-export. **Step 5: Commit** `feat: where-it-gives-up experiment`.

### Task 8: Analysis document

**Files:** Create `analysis/yjit-vs-zjit.md`. Modify `bin/check`.

Formal prose, no swim metaphor, sections exactly spec §8 items 1–8 (+6a "When each compiles"). Every experiment: command, Ruby version, capture file link (`../captures/…`), what it shows. Reconcile the "easy interprocedural type-based specialization" quote with E2 explicitly. ZJIT goals in a "Direction" subsection, attributed + dated. Sources cited as `[n]` → `references/README.md`.

- [ ] **Step 1: Failing check** `check_analysis`: file exists; has headings for all spec §8 sections; every `../captures/…` link resolves; every `[n]` resolves to an entry in references; contains none of `buoy`, `swim`.
- [ ] **Step 2:** Run → FAIL. **Step 3:** Write. **Step 4:** ok. **Step 5: Commit** `docs: formal YJIT vs ZJIT analysis`.

### Task 9: Annotated references

**Files:** Create `references/README.md`. Entries = spec §9 list, numbered `[1]…`, each: authors, title, venue/site, date, URL, "accessed 2026-11-14", the exact quotes used and where (slide name / analysis section). Include the "sources disagree" note verbatim from spec §9.

- [ ] **Step 1: Failing check** `check_references`: every URL in the file returns HTTP 200 (`curl -sfIL`, skip with a warning if offline); every `[n]` used in analysis/talk exists. **Step 2:** FAIL. **Step 3:** Write. **Step 4:** ok. **Step 5: Commit** `docs: annotated references`.

### Task 10: Final README, roam link, release check

**Files:** Modify `README.md`, the roam note (`~/src/dhruvasagar/org-files/roam/20261107000614-the_ceiling_why_ruby_4_0_needed_a_second_compiler.org`: add one line under the title "Moved: the source of truth is ~/src/dhruvasagar/the-ceiling" — do not delete content), `talk/the-ceiling.html` (re-export).

- [ ] **Step 1:** README complete: talk abstract, repo map, reproduce, view/present, "what changes in 4.1 final" + CHANGELOG pointer, licences.
- [ ] **Step 2:** `bin/check` all ok; `git status` clean.
- [ ] **Step 3: Commit** `docs: final README for RubyConf`. Tell the speaker the repo is ready to push, with the exact commands (`gh repo create … --public --source . --push`) for **him** to run, and remind him to replace `[REPO-URL]` on the last slide.
