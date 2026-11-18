# Claims ledger

Every factual comparison the talk makes about YJIT and ZJIT, and the
evidence behind it. A claim is either **shown** (a line in a capture in
[`../captures/`](../captures/), all from Ruby 4.1.0-preview1 at default JIT
settings unless noted) or **stated** (a cited source in
[`../references/README.md`](../references/README.md)). Anything that is the
speaker's interpretation is said on stage as an interpretation, with its
source attributed, and is marked here.

Audited 2026-11-14. If a capture is regenerated, line numbers may move:
search for the quoted text.

## How each one compiles

| Claim (slide) | Kind | Evidence |
|---|---|---|
| The interpreter checks the operand types of `opt_minus` every time it runs, with a fast path for plain numbers (*The bytecode*) | stated | `vm_opt_minus` checks `FIXNUM_2_P` before its fast path, `vm_insnhelper.c:7094` [12]; the instruction in `yarv-distance.txt` |
| YJIT compiles a small piece, runs it, then compiles the next piece when execution reaches it (*YJIT: compile as you go*) | shown + stated | `defer_compilation`, `yjit-distance.txt:122` (*YJIT: in its own words*); "lazily compiles code using a Basic Block Versioning (BBV) architecture" [8] |
| At `a.x`, YJIT guards object, class and shape, then reads `@x` directly (*YJIT: in its own words*) | shown | `# call to Point#x` and the guards after it, `yjit-distance.txt:412` |
| ZJIT records types in the interpreter, then compiles the whole method from that profile (*ZJIT: watch, then plan*) | stated | "reads historical type information from the profiled interpreter", "compiles one entire method at a time" [1]; "uses profile information from the interpreter" [7] |
| ZJIT's IR names every value once (SSA) (*ZJIT: in its own words*) | stated | HIR glossary: "graph representation in static single-assignment (SSA) form" [7] |
| Both compile `distance` during call 30; YJIT logs 25 compile events, ZJIT one; none on calls 31 to 40 (analysis E0; no longer on a slide) | shown | `how-yjit.txt` (first event at :40, all events follow `call 30`), `how-zjit.txt:33` |
| YJIT raises its threshold to 120 calls once a process has 40,000 ISEQs (analysis) | stated | `doc/jit/yjit.md` line 200 [12] |

## Reading the dumps

| Claim (on screen) | Kind | Evidence |
|---|---|---|
| Bytecode steps `0000`-`0010` are `dx = a.x - b.x`: get `a`, call `x`, get `b`, call `x`, minus, store in `dx` (*The bytecode*) | shown | `yarv-distance.txt:5-10` |
| `opt_minus` has a fast path for whole numbers but checks the types each time it runs (*The bytecode*) | stated | CRuby `vm_opt_minus` checks `FIXNUM_2_P` and that `Integer#-` is not redefined on every execution [12] |
| A guard is one quick check per stretch of code; if it fails, a slower path (*Learning to sight*) | shown | guards in `yjit-distance.txt`, `zjit-distance.txt`; YJIT failure targets below; ZJIT `recompile` / side exit [2][7] |
| Each YJIT sight is a compare and a jump (*YJIT: in its own words*) | shown | `tst`/`cmp` + `b.ne`, `yjit-distance.txt:414-436` |
| A failed YJIT sight jumps to a branch stub, which compiles another version (notes) | shown + stated | `b.ne #0x16bbc6284` (`:415`) lands on `# branch stub hit` (`:317`); likewise `:428`→`:353`, `:436`→`:390`; `max_versions` default 4 [12] |
| After the three sights, one load reads `@x` (*YJIT: in its own words*) | shown | `ldur x1, [x11, #0x10]`, `yjit-distance.txt:438` |
| `defer_compilation` is a jump to a stub (*YJIT: in its own words*) | shown | `b #0x16bbc63b4` (`:463`) → `# branch stub hit` at `0x16bbc63b4` (`:440-441`) |

## The five-line method

| Claim | Kind | Evidence |
|---|---|---|
| At the minus, both check for whole numbers (*On five lines, a tie*) | shown | YJIT: `# guard arg0 fixnum`, `# guard arg1 fixnum` after `# Insn: 0008 opt_minus`, `yjit-distance.txt:746-751`; ZJIT: `GuardType v83, Fixnum`, `GuardType v90, Fixnum` before `FixnumSub`, `zjit-distance.txt:53-55` |
| Neither compiler type-checks `dx` again at `dx * dx` (*On five lines, a tie*) | shown | YJIT: `# Insn: 0030 opt_mult` with no guard before the next instruction, `yjit-distance.txt:1428`; ZJIT: `FixnumMult v95, v95`, `zjit-distance.txt:65` |
| ZJIT doesn't re-check `a` and `b` before reading `@y`; YJIT does (*On five lines, a tie*, notes, depth) | shown | ZJIT: `LoadField v79, :@y` with no new guard, `zjit-distance.txt:57`; YJIT: `# call to Point#y` followed by `guard known class` / `guard shape`, `yjit-distance.txt:918` |
| Both call `Math.sqrt` in C (*ZJIT: in its own words*) | shown | ZJIT: `CCallWithFrame v54, :Math.sqrt`, `zjit-distance.txt`; YJIT: `call to Module#sqrt`, `yjit-distance.txt:1651` |

## The turn: `sq`

| Claim | Kind | Evidence |
|---|---|---|
| YJIT compiles `sq` as its own code and `distance` calls it with a real call and a new frame (*At the turn buoy*) | shown | `# call to Object#sq` `yjit-sq.txt:1645`, `push callee control frame`, `gen_direct_jmp: existing block` `:1709` |
| YJIT's `sq` checks `n` (*At the turn buoy*) | shown | `# guard arg0 fixnum` / `guard arg1 fixnum` in `Block: sq@`, `yjit-sq.txt:258` |
| After the call returns, YJIT checks the result again at `+`; ZJIT's add has no check (*At the turn buoy*) | shown | YJIT: `# Insn: 0036 opt_plus` then `# guard arg0 fixnum`, `yjit-sq.txt:2009`; ZJIT: `FixnumAdd v169, v173`, `zjit-sq.txt:94` |
| ZJIT inlines `sq`: no jump, no check on `n` (*At the turn buoy*) | shown | `PushInlineFrame :sq` then `FixnumMult v95, v95`, `zjit-sq.txt:86` |
| ZJIT still sets up a light frame for the inlined `sq` | shown | `--zjit-dump-lir` shows a stack-overflow check, SP save and frame push at `PushInlineFrame`; `empty_inline_frame_count: 0`, `hwia-zjit-stats.txt:93` |
| The cost of a YJIT call: save state, push a frame, jump, run, pop, jump back (*At the turn buoy*) | shown | the comment lines around `# call to Object#sq` in `yjit-sq.txt` (stack overflow check, save PC, push frame, …, pop stack frame) |
| Forced to compile early, YJIT carries "n is a number" into `sq` (Q&A) | shown | `yjit-sq-eager.txt` (`--yjit-call-threshold=1`): the last `Block: sq@` version has no guard at `opt_mult`; the call stays, `:2343` |
| YJIT's architecture "allows for easy interprocedural type-based specialization"; ZJIT's "gives more code at once to the optimizer" (Q&A, *Why it's a ceiling*) | stated | [1] |

## One more call = one more turn buoy

| Claim (on screen) | Kind | Evidence |
|---|---|---|
| Both still make the turn: `n * n` still runs under ZJIT | shown | `PushInlineFrame :sq` then `FixnumMult v95, v95`, `zjit-sq.txt:86-88` |
| YJIT: save the frame, jump to `sq`, check `n`, jump back, check the result | shown | `yjit-sq.txt:1645` (call), `push callee control frame`, `:1709` (jump), `:258` (guard on `n`), `pop stack frame`, `:2009` (check at `+`) |
| ZJIT: no jump, no re-checks; a light frame stays | shown | `zjit-sq.txt:86-94`; `hwia-zjit-stats.txt:93` |

## Why it's a ceiling

| Claim | Kind | Evidence |
|---|---|---|
| YJIT compiles piece by piece; ZJIT compiles a whole method | stated | "Instead of compiling one basic block at a time, it compiles one entire method at a time" [1] |
| YJIT folds in an attribute reader | shown | `a.x` reads `@x` directly after its guards, `yjit-distance.txt:412` |
| In every capture in this talk, a method doing real work (`sq`, `convert_key`, `double`) stays a real call under YJIT | shown | `yjit-sq.txt:1645`, `hwia-yjit-disasm.txt:63247`, `yjit-choppy.txt:214` |
| YJIT has a low-level IR inside its code generator (Q&A) | stated | `yjit/src/backend/ir.rs` [12] |
| *Interpretation:* inlining and optimising across a call is natural with a whole-method plan, and this is the "ceiling" | attributed | "raise the performance ceiling (bigger compilation unit size and SSA IR)" [2]; "gives more code at once to the optimizer" [1]. Said on stage as the team's words. |

## The plateau

| Claim (on screen) | Kind | Evidence |
|---|---|---|
| Straight code (`dx * dx`): no type check in either | shown | `yjit-distance.txt:1428`, `zjit-distance.txt:65` |
| At a call to a small method, YJIT checks the argument, makes a real call, checks the result | shown | `yjit-sq.txt:258` (guard on `n`), `:1645` (call), `:2009` (check at `+`) |
| ZJIT copies the method in and drops the checks on both sides; a light frame stays | shown | `zjit-sq.txt:86` (`PushInlineFrame`), `FixnumMult v95, v95`, `:94` (unguarded `FixnumAdd`); `hwia-zjit-stats.txt:93` |
| A design limit: YJIT never sees the whole method | stated | "YJIT compiles one basic block at a time, so it never has the full picture of the function anyway" [15]; "raise the performance ceiling" [2] |

## So, why build the second one?

| Claim (on screen) | Kind | Evidence |
|---|---|---|
| The next gains need the whole method as one plan; a compiler that works piece by piece never has one | stated + shown | "raise the performance ceiling (bigger compilation unit size and SSA IR)" [2]; "YJIT compiles one basic block at a time, so it never has the full picture of the function anyway" [15]; shown at the turn buoy (E3) and in `params` (E4b) |
| A more traditional compiler, so more people can help build it | stated | "encourage more outside contribution (by becoming a more traditional method compiler)" [2]; "a more traditional “textbook” compiler so it is easy for the community to contribute to" [1] |

## Trade-offs

| Claim | Kind | Evidence |
|---|---|---|
| If behaviour changes after compiling, ZJIT side-exits and can recompile | stated + shown | "we will frequently side-exit into the interpreter" [2]; `recompile` on guards in every HIR capture |
| YJIT adds another version of a piece, up to 4 by default | stated | `max_versions: 4`, `yjit/src/options.rs` [12] |

## Real code: `HashWithIndifferentAccess#[]`

| Claim | Kind | Evidence |
|---|---|---|
| Rails `params` is built on `HashWithIndifferentAccess` (*Race day: params*) | stated | `@parameters = parameters.with_indifferent_access`, Rails `strong_parameters.rb:294` [13] |
| The method source (*Race day: params*) | shown | `hwia-source.txt` (activesupport 8.1.4.1) |
| YJIT calls `convert_key` with a real call (*params, through both*) | shown | `hwia-yjit-disasm.txt:63247` |
| ZJIT inlines `convert_key` and turns `Symbol === key` into a type test and branch | shown | `PushInlineFrame :convert_key` `hwia-zjit-hir.txt:3980`; `IsA v10, v43` `:3985` |
| Both compile `super` as a call to `Hash#[]` in C | shown | ZJIT: `CCallWithFrame v27, :Hash#[]` `hwia-zjit-hir.txt:4005`; YJIT: `# call C function` after `invokesuper` `hwia-yjit-disasm.txt:63436` |
| With a literal key, ZJIT inlines `[]` and `convert_key` into the caller and folds `Symbol === :id` away (depth note) | shown | `fn block in <main>` `hwia-zjit-hir.txt:4010`: `PushInlineFrame :[]`, `PushInlineFrame :convert_key`, and no `IsA`/`CondBranch` in that function |

## A glimpse: seven everyday lines

The table on the slide is generated from `glimpse-yjit.txt` and
`glimpse-zjit.txt` by `bin/lib/glimpse.rb`, and `bin/check glimpse` fails
if the slide and the captures disagree. Rules: count calls into Ruby
methods only (methods YJIT compiled blocks for in activesupport files);
calls into C are left out under both compilers.

| Claim | Kind | Evidence |
|---|---|---|
| Each row's YJIT and ZJIT counts | shown | generated from the captures by `bin/lib/glimpse.rb` |
| YJIT inlines `NilClass#blank?` | shown | `inlined simple ISEQ` after `# call to NilClass#blank?`, `glimpse-yjit.txt` |
| ZJIT folds `nil.blank?` to `true` | shown | `Const Value(true)` in the caller, `glimpse-zjit.txt` |
| ZJIT does not inline `try` (calls it directly) | shown | `SendDirect … :try`, `glimpse-zjit.txt` |
| Inlined is not free: ZJIT sets up a light frame | shown | see "The turn: sq" above |

## Polymorphism: `double`

| Claim | Kind | Evidence |
|---|---|---|
| Calm: ZJIT inlines `double`, one guard, one add | shown | `GuardType v10, Fixnum`, `FixnumAdd v44, v44`, `zjit-calm.txt:21` |
| Choppy: every ZJIT case is a call into C, even Integer; then a polymorphic fallback | shown | `:Integer#+` `zjit-choppy.txt:39`; `polymorphic fallback` `:57` |
| Choppy: YJIT keeps an inline integer add and a version per type | shown | `guard arg0 fixnum` (no call) plus `call to Float#+`, `String#+`, `Array#+`, `Rational#+` in `yjit-choppy.txt` |
| Choppy: ZJIT inlines `double`; YJIT calls it | shown | `PushInlineFrame :double` `zjit-choppy.txt:18`; `# call to Object#double` `yjit-choppy.txt:214` |
| Neither bails out to the interpreter: 0 side exits each | shown | `side_exit_count: 0`, `zjit-choppy-stats.txt:40`, `yjit-choppy-stats.txt:94` |

## Measured: the ZJIT team's results, and ours

| Claim | Kind | Evidence |
|---|---|---|
| setivar: YJIT 5 ms, ZJIT 2 ms per iteration | stated | "ZJIT takes an average of 2ms per iteration on this benchmark, while YJIT takes an average of 5ms." [14] |
| Storefront JIT memory: YJIT 125 MiB, ZJIT 101 MiB | stated | "YJIT takes 125MiB and ZJIT takes 101MiB" [3] |
| Storefront: "probably as fast as or faster than YJIT"; "there are definitely some where we are worse" | stated | [3] |
| ZJIT generates more code | stated + shown | "we generate more code …" [3]; ours: `code_region_bytes: 360,448` (ZJIT) vs `code_region_size: 327,680` (YJIT), `hwia-*-stats.txt` (each compiler's own counter) |
| Ruby calls in `params[:name].present?`: YJIT 4, ZJIT 0 | shown | glimpse table, `bin/lib/glimpse.rb` |
| No bail-outs in choppy water, either compiler | shown | `side_exit_count: 0`, `zjit-choppy-stats.txt:40`, `yjit-choppy-stats.txt:94` |

## Status and dates

| Claim | Kind | Evidence |
|---|---|---|
| Ruby 4.0 shipped 2025-12-25 with ZJIT, "the next generation of YJIT" | stated | [4] |
| 4.0 goal: "faster than YJIT and production-ready in Ruby 4.1" | stated | [4] |
| October 2026: "probably as fast as or faster than YJIT", on Shopify's storefront, "a couple small regions" | stated | [3] |
| 4.1 NEWS: faster on many benchmarks, may be slower on larger apps; method inlining | stated | [5] |

## Not claimed

These were considered and left out because they aren't supported by our
captures or sources:

- Any speed number of our own (dev builds; see the analysis, §9).
- "ZJIT is from the same team as YJIT" (no source states it).
- "YJIT inlines one-line methods returning a constant, `self` or an
  argument" (not verified here; the talk claims only what the captures
  show).
- "ZJIT has to wait longer than YJIT before compiling" (both compile at
  call 30 in E0).
