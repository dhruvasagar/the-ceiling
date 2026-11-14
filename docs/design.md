# The Ceiling — talk + companion repo: design

Status: draft for Dhruva's approval · 2026-11-14

## 1. Intent

A 20-minute RubyConf talk, **"The Ceiling: Why Ruby 4.0 Needed a Second
Compiler"**, plus a **public GitHub repo** (linked from the last slide) that
holds the complete presentation, the runnable source behind every slide, a
formal written analysis of YJIT vs ZJIT, and the references.

The talk answers one question for an audience that is mostly beginners to
JIT internals: *Ruby already had YJIT and it works — why build ZJIT?* The
answer the room should leave with, in one sentence:

> "YJIT compiles Ruby a bit at a time, deciding as it goes; ZJIT plans a
> whole method at once, so it can see through small method calls and stop
> paying for them. That's the room Ruby needed to keep getting faster."

(Builder's call, made at design time: the earlier "forgets at every method
call" wording overstated what the captures show — see §9. If the E2
reconciliation finds YJIT's re-guard in `sq` is incidental to this version
or call shape, **keep the "One more call" slide and narrow the claim** to
exactly what the capture shows ("here, it checked again"); do not rework
the arc. The builder may adjust this sentence's wording to stay true to the
captures; changes to its meaning go to the speaker.)

The ZJIT team's own wording backs the title directly (Max Bernstein,
launch post, 2025-12-24): *"we want to both raise the performance ceiling
(bigger compilation unit size and SSA IR) and encourage more outside
contribution (by becoming a more traditional method compiler)."*

### Why it matters (from the original brief)
- Most of the room will upgrade into ZJIT (4.1, ~weeks after the talk)
  without ever having looked at what changed.
- "Ruby is slow" is said on reflex in rewrite debates; reading the
  compiler's output gives people something specific to say instead.

### ZJIT's goals are in scope (speaker, at approval)
The comparison and the "why" may draw on ZJIT's **stated larger goals**,
not only what ships today: e.g. a general-purpose method inliner ("in the
fullness of time"), a more traditional compiler shape that outside
contributors can work on, and the performance-ceiling argument. Rule:
every goal is attributed and dated to a team source (§9) and presented as
a goal or direction, never as current behaviour; current behaviour stays
backed by captures.

### Primary objective (speaker, restated)
Above everything else, the talk must **clearly explain how YJIT and ZJIT
differ, and why the team built ZJIT at all**, through explanations the
audience can *see demonstrated*, not just hear. Every difference claimed on
stage is backed by a demonstration (§6a).

## 2. Audience

- Know the words *interpreter*, *bytecode*, *compiler*.
- Do **not** know how a JIT works, how YJIT decides what to compile, or
  what ZJIT does differently.
- The speaker is also not deep in either JIT. Every explanation must be
  simple enough that he can tell it confidently and answer a follow-up
  without reaching for internals. Depth lives in speaker notes and the
  analysis doc, not on slides.

## 3. Goals, non-goals, anti-goals

**Goals**
1. Keep every promise of the original brief: why a second JIT; YJIT
   "watches types, optimises small chunks" vs ZJIT "whole method, proves
   instead of guesses"; trace one five-line method through both with its
   IR on one slide; show where ZJIT wins and where it gives up; the same on
   a hot method from a gem the audience has deployed; explain ideas only
   when the example needs them; leave the audience able to read this for
   their own code and knowing which hot paths no JIT can help.
2. Story-driven: an **open-water swimming** story (the speaker's own
   experience learning it) carries the whole talk and holds attention.
3. Beginners follow it without being overwhelmed; they leave intrigued
   enough to open the repo.
4. Say what it means for Ruby's future.
5. The repo lets anyone reproduce every listing and number.

**Non-goals**
- Benchmarking YJIT vs ZJIT speed (cite the team's numbers; don't make
  our own speed claims).
- Teaching compiler theory (SSA, basic-block versioning) on stage.
- Covering every JIT option or internals detail.

**Anti-goals** (a failure even if it "works")
- A slide line that doesn't exist in a real capture, or a claim neither a
  capture nor a cited source supports.
- An advert for ZJIT. Where YJIT is the better fit, say so.
- The room decoding vocabulary instead of following the story.
- Swim metaphor stretched past where it maps honestly.

## 4. Decided: the storytelling device

Open-water swimming, with **one image per idea**:

| Ruby idea | Swim picture |
|---|---|
| Interpreter re-checking types on every instruction | Beginner lifts their head **every stroke** to see. Safe, slow. |
| JIT + **guard** | Trained swimmer looks once (sighting), head down. Off course? Stop, look around properly (fall back to interpreter). |
| YJIT (lazy basic block versioning) | Swims **buoy to buoy**: in the water immediately, decides each leg at the buoy from what it sees right then. |
| ZJIT (**profile**, then whole-method SSA IR) | **Studies the course first**: warm-up lap + course map on the beach, then swims the whole loop planned. "Prove, don't guess." |
| Method call boundary | **Turn buoy**. YJIT lifts its head again; ZJIT already knows the next line (**inlining**). |
| PatchPoint / invalidation | Officials move a buoy → the plan is thrown away. (notes only) |
| Why ZJIT was built (the ceiling) | **The 2-beat kick** (speaker's own practice). Long-distance swimmers cut kicks to two per stroke cycle for efficiency. You can't get there by improving each kick on its own; the kick has to be timed to the *whole* stroke cycle. Optimising piece by piece (YJIT) has a top speed; the next gains need the whole cycle in view (ZJIT, whole method). |
| Polymorphic / dynamic Ruby | **Fog and chop**: everyone swims head-up again. |
| DB, C code, GC | **Feed stops**: in a long swim you stop at the support boat to drink. A better stroke doesn't make the feed stop shorter. Presented as a general long-distance image, *not* as the speaker's personal story unless he confirms it. (Replaces "bike and run legs": the speaker swims open water only, no triathlon.) |
| Warmup cost | **Time on the beach** before the start. |

Only four technical words go on slides: **guard, profile, inlining, IR**.
Everything else (shapes, side exits, SSA, Fixnum/Bignum, PatchPoint,
CCallWithFrame) goes in speaker notes and the analysis doc.

### Story arc (the narrative spine)
1. **Hook** — the speaker's first open-water swim: lifting his head every
   stroke, exhausted, and the coach's line: *"every time you lift your
   head, you slow down."*
2. **Learning to sight** — the trained swimmer (what a JIT is).
3. **Two swimmers** — buoy-to-buoy (YJIT) vs course-planner (ZJIT).
4. **The turn buoy** — the climax: one extra method call, and only one of
   them has to look up.
5. **Why the second swimmer was trained** — the ceiling, told through the
   2-beat kick: the gain you can't reach one kick at a time.
6. **Honest limits** — the long swim: chop, and the feed stops.
7. **Resolution** — what this means for Ruby, and "go read your own swim
   log" (the repo, three commands).

The speaker's real experience is the source of the anecdotes. **The
builder drafts the anecdote beats as placeholders marked `[STORY: …]` with
a suggested line; the speaker replaces them with his own words.** Do not
invent biographical facts.

## 5. Decided: slide pattern

Every technical idea: **swim diagram first (picture), then a "proof"
slide** with real compiler output trimmed to ~3–8 lines, the relevant
lines highlighted, and a one-line plain-English caption under each side
("B" layout: YJIT left, ZJIT right). Approved for the key slide; apply
throughout.

## 6. Decided: talk outline (20 min, ~1 min slack)

| Start | Slide | Swim picture | Proof on screen | New word |
|---|---|---|---|---|
| 0:00 | Two JITs. Why? | Hook: first swim, coach's line | — | |
| 1:00 | How Ruby runs your code | Head up every stroke | **LIVE** YARV disasm (`C-c C-c`); `opt_minus` doesn't know types | |
| 2:30 | What a JIT does | Sight once, head down | — | guard |
| 3:30 | YJIT: buoy to buoy | Buoy diagram | 4–6 YJIT comment lines (`# guard …`, `defer_compilation`) | |
| 6:00 | ZJIT: study the course | Course map | The IR on one slide (~8 lines) | profile, IR |
| 8:30 | Same five lines, a first wave | Wave mid-leg | YJIT re-guard at `dx * dx` after `Math` lookup vs ZJIT `FixnumMult v95, v95` | |
| 9:30 | One more call (**key**) | Turn-buoy diagram (A) | Side-by-side (B): YJIT `guard arg0/arg1 fixnum` in `sq` vs ZJIT `PushInlineFrame` + `FixnumMult v95, v95` | inlining |
| 12:30 | Why ZJIT was built | 2-beat kick: whole cycle, not each kick; cost = time on the beach | The team's quote: "raise the performance ceiling (bigger compilation unit size and SSA IR) and encourage more outside contribution" | |
| 14:30 | A method you already run: `params[:id]` | Great stroke… but most of the time is the feed stop | HWIA source; `Hash#[]` top C call (stats) | |
| 16:30 | Where it gives up | Fog & chop + feed stops | New capture (see §8, open) | |
| 18:00 | What it means for Ruby | Small methods stop costing extra | 3 commands to read your own code; repo link | |
| 19:00 | Close | "Which part is slow?" | — | |

"Round 1: a draw" is **removed**: real captures (4.1.0-preview1) show YJIT
re-guards `dx` at `dx * dx` because the `Math` constant lookup clears its
local types, while ZJIT does not. That becomes the "first wave" slide.

## 6a. Demonstrations (the primary objective, made concrete)

Each difference the talk claims gets one demonstration the audience can
see: a live `C-c C-c` block or a captured listing from the repo.

| Difference | Demonstration | Status |
|---|---|---|
| **When** each compiles: YJIT on first call, a bit at a time; ZJIT only after watching the method run | Run with `--yjit-call-threshold=1` (shows `defer_compilation` stubs) vs `--zjit-trace-compiles` with the default threshold, showing ZJIT compiling `distance` only after N calls | **new**: builder adds capture |
| **What** each compiles: block vs whole method | YJIT `# Block:` headers (many small) vs one `fn distance@…` HIR | captured |
| **How far knowledge carries** | E1 "first wave": YJIT re-guard at `dx * dx` after `Math`; ZJIT none | captured |
| **Seeing through a method call** (inlining) | E2: YJIT guards inside `sq`; ZJIT `PushInlineFrame` + unguarded `FixnumMult` | captured |
| **Where neither helps** | E3 (`Hash#[]` in C) + E4 (give-up) | E3 captured, E4 open |

The "when" row is new and important: it is the most beginner-visible
difference (buoy-to-buoy starts swimming at once; the planner waits on the
beach), and it shows the warmup cost honestly.

## 7. Decided: repo

- **Location**: `~/src/dhruvasagar/the-ceiling/` (name: builder's call if
  a better one emerges, but keep it short).
- **Public on GitHub**, linked from the final slide.
- **Licences**: MIT for code, CC BY 4.0 for prose/slides (builder's call
  — speaker can override).
- **Layout** (shape decided, filenames builder's call):
  ```
  README.md            what this is, how to reproduce, how to view the talk
  talk/                the complete presentation (org + reveal.js export)
  src/                 demo Ruby programs + capture scripts
  captures/            checked-in raw outputs the slides are cut from
  analysis/            the formal YJIT vs ZJIT write-up
  references/          annotated bibliography
  ```
- **Presentation format**: Org mode exported with org-re-reveal (as the
  existing draft), so the live `C-c C-c` blocks still work from Emacs.
  Speaker notes in `#+begin_notes`. A static HTML export is committed so
  people can view it without Emacs.
- **Reproducibility**: pinned Ruby via `.tool-versions`; README documents
  building Ruby with `--enable-yjit=dev --enable-zjit=dev` (needed for
  `--yjit-dump-disasm`; `--zjit-dump-hir` is not gated to a dev build per
  `zjit/src/options.rs`, but verify on the release). Capture scripts runnable
  from a plain shell (not only Emacs). No personal paths in committed
  files; strip memory addresses from published listings.
- **Source of truth**: the repo. The existing roam note
  (`org-files/roam/20261107000614-the_ceiling_…org`) stays where it is and
  gets a link to the repo; it is not deleted. Its working parts (noweb
  slide→file tangling, auto-tangle `:dir`, asdf shim prologue) carry over.

## 8. Analysis document (audience-facing, formal)

Plain, formal prose — **no swim metaphor**. Stands on its own. Covers:
1. How CRuby runs code (YARV bytecode, interpreter) — brief.
2. YJIT: lazy basic block versioning; type context; guards; side exits;
   strengths (fast warmup, no profiling phase, "easy interprocedural
   type-based specialization" per the team) and limits.
3. ZJIT: interpreter profiling (`--zjit-num-profiles`, `--zjit-call-threshold`),
   whole-method SSA HIR, guards with recompile, PatchPoints, inlining
   (status in 4.0 vs 4.1), side exits.
4. Side-by-side comparison table (unit of compilation, type source,
   when it compiles, how knowledge propagates, invalidation, memory —
   125 MiB vs 101 MiB on SFR per the team).
5. Experiments, each with the exact command, Ruby version, the capture
   file, and what it shows:
   - E1 `distance` (straight-line): both guard + specialise; YJIT loses
     local types at the `Math` lookup; ZJIT doesn't.
   - E2 `distance` with `sq`: ZJIT inlines (`PushInlineFrame`, no guard);
     YJIT compiles `sq` separately and re-guards.
   - E3 `HashWithIndifferentAccess#[]`: time dominated by `Hash#[]` in C;
     no `invokesuper` side exits on either.
   - E4 "where it gives up" (**open, builder must complete**): preliminary
     run of `double(x) = x + x` over mixed types showed few side exits
     (ZJIT 11, YJIT 0) — both handle it by falling back to general/
     polymorphic paths rather than bailing out. The builder designs an
     experiment that *visibly* shows the loss (e.g. compare HIR before/
     after the types change, or `--zjit-stats` counters like
     `dynamic_send_count` / `guard_type_failure`), and the slide states
     exactly what it shows. If no clean "gives up" exists, the slide is
     "stops guessing, swims head-up again", not "bails out".
6. Where no JIT helps (I/O, C code, GC, highly dynamic code).
6a. When each compiles: call thresholds, YJIT's immediate lazy
   compilation vs ZJIT's profile-then-compile (`--zjit-num-profiles`,
   `--zjit-call-threshold`, default 30), and the warmup trade-off.
7. Status and future: 4.0 (slower than YJIT), Oct 2026 parity post,
   4.1 goals and caveats — quoted, with the disagreements between sources
   stated plainly (see §9).
8. Threats to validity: preview build, dev-mode builds, toy workloads,
   versions.

## 9. References (verified 2026-11-14; quotes exact)

- Bernstein, "ZJIT has been merged into Ruby", Rails at Scale, 2025-05-14 —
  https://railsatscale.com/2025-05-14-merge-zjit/ ("textbook compiler";
  method-at-a-time; reads profiled interpreter types; YJIT allows "easy
  interprocedural type-based specialization").
- Bernstein, "ZJIT is now available in Ruby 4.0", 2025-12-24 —
  https://railsatscale.com/2025-12-24-launch-zjit/ ("raise the performance
  ceiling…"; 4.0 limited inliner; side exits when call patterns change).
- Bernstein, "ZJIT is now as fast as YJIT", 2026-10-09 —
  https://railsatscale.com/2026-10-09-zjit-is-now-as-fast-as-yjit/
  (parity on SFR in small regions; some benchmarks worse; memory numbers).
- Ruby 4.0.0 release notes, 2025-12-25 —
  https://www.ruby-lang.org/en/news/2025/12/25/ruby-4-0-0-released/
  ("next generation of YJIT"; goal "faster than YJIT and production-ready
  in Ruby 4.1").
- Ruby master NEWS.md (4.1) — method inlining incl. methods that yield;
  "faster than YJIT on many benchmarks… can be still slower… on larger
  benchmarks".
- ruby/ruby `doc/jit/zjit.md`, `doc/jit/yjit.md`.
- Chevalier-Boisvert et al., "YJIT: a basic block versioning JIT compiler
  for CRuby", VMIL 2021 — https://doi.org/10.1145/3486606.3486781 (and the
  MPLR 2023 paper yjit.md asks to cite: https://doi.org/10.1145/3617651.3622982).
- Chevalier-Boisvert & Feeley, "Simple and Effective Type Check Removal
  through Lazy Basic Block Versioning", ECOOP 2015 — https://arxiv.org/abs/1411.0352.

**Sources disagree** on the 4.1 target ("on par" 2025 → "faster than
YJIT" in 4.0 notes → "faster on many benchmarks, maybe slower on larger
apps" in 4.1 NEWS → "probably as fast or faster" on one workload, Oct
2026). The talk and analysis quote them, dated, rather than picking one.
The talk's opening notes currently say "parity in 4.1" — fix to match.

**Tension to handle honestly**: the team says YJIT's architecture "allows
for easy interprocedural type-based specialization", while our E2 capture
shows YJIT re-guarding inside `sq`. The analysis must reconcile this (e.g.
what YJIT can carry across calls vs what it did here) rather than imply
YJIT never can. The talk's "forgets at every method call" line must be
worded to match what the captures show ("here, it checked again").

## 10. Constraints

- **Dates**: draft presentation due **2026-11-15** (tomorrow); talk on
  **2026-11-21**. Ruby 4.1.0 final ships 2026-12-25, *after* the talk.
- **Phasing**:
  1. **By 11-15 (draft):** the complete presentation (all slides, swim
     diagrams, proof listings, speaker notes with `[STORY: …]`
     placeholders), the `src/` + `captures/` it depends on, and a minimal
     README. This is what gets submitted.
  2. **By 11-21 (talk):** the analysis document, annotated references,
     full README, the "when it compiles" capture and E4, rehearsal-driven
     edits, and the public repo ready to push (speaker pushes).
  3. **After 12-25:** re-run captures on 4.1.0 final, diff, and publish
     corrections in the repo (CHANGELOG note). Not needed for the talk.
- The talk runs on **4.1.0-preview1**. Slides that show compiler output
  carry a small "Ruby 4.1.0-preview1" label; spoken claims about 4.1 are
  dated quotes from the team, not predictions.
- 20 minutes, ~1 min slack; the key slides ("One more call", "Why ZJIT
  was built") are never cut.
- Presenting from Emacs shows `#+begin_notes` on the projector with
  org-tree-slide/org-present; present the reveal export with Emacs only
  for the live block, or hide notes.

## 11. Left to the builder

- Exact filenames, diagram tooling (inline SVG in reveal is fine),
  slide visual style, README wording.
- Drafting slide text and speaker notes in plain language within §4–6.
- Designing and running E4; adding any capture the analysis needs.
- Whether captures run via a Makefile/Rake task or shell scripts.
- Placeholders for personal story beats (`[STORY: …]`).
- Initial `git init` and local commit; **pushing to GitHub / creating the
  remote is the speaker's step** (or done only with his explicit go-ahead).

## 12. Revision (2026-11-14, evening): story and evidence

**Story.** The talk follows one swimmer, the speaker, getting better at
open water, and Ruby's journey alongside: head up (interpreter) →
sighting (YJIT) → the plateau, where the time left is at the turns
(method calls) → planning the line and the 2-beat kick (ZJIT, inlining) →
race day (C code and waiting as feed stops; polymorphism as chop) → a
closing swim that returns to the coach's line. Pictures come before code.
Choppy water is a limit for both compilers, so it sits in race day, not
at the turning point. Personal beats remain `[STORY: …]` placeholders,
including the closing swim.

**Evidence.** All captures now use default JIT settings. The "first wave"
slide is removed: YJIT's re-check after the `Math` lookup only appears
when it is forced to compile on the first call (before the constant cache
fills), and is gone once it recompiles. The turn-buoy slide now rests on
what holds at default settings: YJIT makes a real call into a separately
compiled, general `sq` that checks its argument; ZJIT inlines `sq` with no
call and no check. A forced-early capture (`yjit-sq-eager.txt`) is kept
for the analysis, where it shows YJIT carrying the type across the call.
