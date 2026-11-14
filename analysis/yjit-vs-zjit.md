# YJIT and ZJIT: how they differ, and why ZJIT exists

A companion to the talk *The Ceiling: Why Ruby 4.0 Needed a Second
Compiler*. The talk tells this as a story; this document states it
plainly, with the commands and outputs behind every claim.

All experiments were run on **Ruby 4.1.0-preview1** (2026-10-11, arm64
macOS), built with `--enable-yjit=dev --enable-zjit=dev`, and activesupport
8.1.4.1. Outputs are in [`../captures/`](../captures/); each file's first
line is the exact command. Numbers in brackets, like [2], refer to
[`../references/README.md`](../references/README.md).

## Summary

YJIT and ZJIT are both just-in-time compilers inside CRuby, both written
in Rust by the same team, and both turn hot Ruby methods into machine code
guarded by cheap type checks. They differ in **what they compile at once**
and **where their type information comes from**:

- **YJIT** uses *lazy basic block versioning* [8][9][10]. It compiles one
  small straight-line piece (a basic block) at a time, specialised on the
  types it observes at that moment, and carries what it knows forward to
  the next piece.
- **ZJIT** is a *method-based* compiler [7]. It first records the types the
  interpreter sees (a profile), then compiles the whole method at once into
  a graph in SSA form (its HIR), and optimises across that whole graph.

The team built ZJIT to "raise the performance ceiling (bigger compilation
unit size and SSA IR) and encourage more outside contribution (by becoming
a more traditional method compiler)" [2]. Our experiments show one
concrete form of that ceiling. At a small method call, at default
settings, ZJIT inlines the callee into the caller and reuses a type it has
already proved; YJIT makes a real call into a separately compiled, general
version of the callee, which checks its argument again (E3).

## 1. How CRuby runs code

CRuby compiles Ruby source to bytecode for its virtual machine, YARV, and
interprets that bytecode. YARV is a stack machine whose instructions are
generic: `opt_minus` subtracts whatever two values are on the stack, so on
every execution it has to establish what those values are
([`yarv-distance.txt`](../captures/yarv-distance.txt)). A JIT compiler
removes most of that repeated work by generating machine code that checks
the types once (a **guard**) and then performs the specialised operation.
If a guard fails, the compiled code cannot continue: it leaves for a slower
path, either the interpreter (a **side exit** [7]) or, in YJIT's case,
often another compiled version for the new type (§2).

Both JITs start from the same bytecode. Neither can optimise inside
methods written in C (`Hash#[]`, `Math.sqrt`, `Integer#+` when not
specialised); they can only call them.

## 2. How YJIT works

YJIT compiles lazily, one basic block at a time [8]. When a method becomes
hot, YJIT compiles its first block. Where the next block depends on a
value it hasn't seen, it emits a stub and stops (`defer_compilation` in
its disassembly). When execution reaches the stub, YJIT inspects the live
values and compiles the next block specialised for them. If a later
execution arrives with different types, it compiles another *version* of
that block. A per-block *type context* carries what YJIT has proved (for
example, "local `dx` is a fixnum") from one block to the next, so later
blocks can skip checks.

The technique comes from Chevalier-Boisvert and Feeley's lazy basic block
versioning [9], which removed 71% of type tests on average in its original
evaluation; YJIT's design and production results are described in [10]
and [11].

Strengths: no separate profiling phase; it compiles only code that
actually runs, for types that actually occur, so little is wasted; and,
in the team's words, its architecture "allows for easy interprocedural
type-based specialization" [1].

Limits: the unit of compilation is small. Optimisations that need to see
many blocks at once, across branches or across calls, are hard to add to a
compiler that decides one block at a time before the next one exists.

## 3. How ZJIT works

ZJIT is "a method-based just-in-time (JIT) compiler for Ruby. It uses
profile information from the interpreter to guide optimization" [7].
Before compiling, the interpreter records the types seen at each
instruction for a number of calls (`--zjit-num-profiles`, default 5) [7].
When the method reaches the call threshold (`--zjit-call-threshold`,
default 30) [7], ZJIT compiles the **whole method** into HIR, a graph in
static single-assignment (SSA) form, in which every value is defined
exactly once [7]. Because each value has a single definition, a fact
proved about it (for example, that `v95` is a fixnum) holds at every use,
and optimisation passes can work across the entire method.

Other elements visible in the captures:

- `GuardType` checks a value's type; on failure ZJIT side-exits and can
  `recompile` with better information.
- `PatchPoint` records an assumption (for example, "`Point#x` has not been
  redefined"); if it is broken, the compiled code is invalidated.
- `LoadField` reads an instance variable directly when the method is a
  plain `attr_reader`.
- `CCallWithFrame` calls a C function.
- `PushInlineFrame` / `PopInlineFrame` bracket an inlined callee. The 4.1
  NEWS describes method inlining, "including methods that yield to a
  block" [5]; in 4.0 the inliner was limited to constants, `self` and
  parameters [2].

The team notes the cost of profile-driven compilation: "if your method
call patterns change significantly after your code has been compiled, we
will frequently side-exit into the interpreter" [2].

## 4. Side by side

| | YJIT | ZJIT |
|---|---|---|
| Unit of compilation | basic block | whole method |
| Type information from | live values when a stub is reached | interpreter profile, gathered before compiling |
| Representation | per-block code with a type context | SSA graph (HIR) for the method |
| Knowledge travels | forward, block to block | across the whole method graph |
| Polymorphic sites | one block version per type seen | type switch in one compiled body |
| Calls to small Ruby methods | a real call into separately compiled code (E3, default settings) | inlined into the caller (E3) |
| Default call threshold (preview1) | 30 (E0) | 30 [7] (E0) |
| Memory on Shopify SFR | 125 MiB [3] | 101 MiB [3] |
| Status | mature; evaluated in production at Shopify [11] | 4.0: slower than YJIT [4]; 4.1 previews: faster on many benchmarks [5] |

## 5. When and how each one compiles

**E0. One method, logged.** [`how-yjit.txt`](../captures/how-yjit.txt),
[`how-zjit.txt`](../captures/how-zjit.txt). `distance` is called 40 times
with default settings, printing the call number. Both JITs compile it on
**call 30**: the defaults match, so neither starts earlier. The difference
is the shape: YJIT logs **25** compile events for `distance`, at
increasing bytecode positions (`index: 0` … `index: 42`), as execution
reaches each block; ZJIT logs **one**, for the whole method. ZJIT's
profile was gathered during earlier calls by the interpreter.

## 6. Experiments

The programs are generated from the talk file into [`../src/`](../src/).
Each slide listing in the talk is a verbatim excerpt of these captures,
checked by `bin/check`.

**E1. Straight-line code: `distance`.**
[`yjit-distance.txt`](../captures/yjit-distance.txt),
[`zjit-distance.txt`](../captures/zjit-distance.txt).

```ruby
def distance(a, b)
  dx = a.x - b.x
  dy = a.y - b.y
  Math.sqrt(dx * dx + dy * dy)
end
```

Both compilers guard the receivers' class and shape, read `@x`/`@y`
directly instead of calling the readers, guard the operands as fixnums,
and emit an overflow-checked subtract. Both call `Math.sqrt` in C.

**E2. Knowledge kept within the method.** Same captures. Neither compiler
re-checks `dx` before `dx * dx`. ZJIT emits `FixnumMult v95, v95` with no
guard: `v95` was produced by `FixnumSub` and is a fixnum by construction.
YJIT's type context carries "fixnum" from the subtract to the multiply, and
its `opt_mult` blocks at 0030 and 0036 go straight to the multiply.

A caution about capture settings. With `--yjit-call-threshold=1`, YJIT
compiles `distance` on its first call, before the `Math` constant cache is
filled. That first version takes a slow constant lookup that clears its
local types, so its multiply *does* re-check `dx`. YJIT later invalidates
and recompiles that block, and the recompiled multiply has no check. An
earlier draft of this talk mistook that cold-start version for YJIT's
steady state. Every capture behind the talk now uses default settings.

**E3. One more call: `sq`.**
[`yjit-sq.txt`](../captures/yjit-sq.txt),
[`zjit-sq.txt`](../captures/zjit-sq.txt).

```ruby
def sq(n) = n * n
# distance now ends: Math.sqrt(sq(dx) + sq(dy))
```

At default settings `sq` is called twice per call of `distance`, so it
reaches the threshold first and YJIT compiles it on its own, for any
caller: its `opt_mult` guards both operands (`guard arg0 fixnum`,
`guard arg1 fixnum`). When `distance` is compiled later, YJIT emits a real
call (`call to Object#sq`, `push callee control frame`) and jumps into that
existing code (`gen_direct_jmp: existing block`); `sq` then pops its frame
and returns. ZJIT inlines `sq` at both call sites: `PushInlineFrame :sq …`,
`FixnumMult v95, v95`, `PopInlineFrame`, with no call and no guard on `n`,
because `n` *is* `v95`.

The difference that holds in every run is **a real call versus no call**.
Whether YJIT re-checks `n` depends on what it compiled first. With
`--yjit-call-threshold=1`
([`yjit-sq-eager.txt`](../captures/yjit-sq-eager.txt)) YJIT compiles
`distance` before `sq`, and once its blocks settle, the version of `sq`
reached from `distance` multiplies with no guard: YJIT carried "`n` is a
fixnum" across the call. That is the team's point that YJIT's architecture
"allows for easy interprocedural type-based specialization" [1]. The call
itself, with its frame push and pop, remains. ZJIT's architecture "gives
more code at once to the optimizer" [1], and inlining is one thing the
optimizer does with it.

**E4. A gem method: `HashWithIndifferentAccess#[]`.**
[`hwia-source.txt`](../captures/hwia-source.txt),
[`hwia-yjit-stats.txt`](../captures/hwia-yjit-stats.txt),
[`hwia-zjit-stats.txt`](../captures/hwia-zjit-stats.txt).
Rails `params` (`ActionController::Parameters`) is built on it. 100,000
iterations, each looking up one Symbol key and one String key:

```ruby
def [](key)
  super(convert_key(key))
end

def convert_key(key)
  Symbol === key ? key.name : key
end
```

ZJIT's statistics list `Hash#[]` as its most frequent call into C from JIT
code (199,971 calls, 64.4% of all such calls). YJIT's `invokesuper` exit
counters are all zero; it fell back to a generic `super` 57 times (reason
`singleton_class`). Neither compiler side-exits on the `super`. These are
call counts, not timings: we did not profile where the time goes. What
they show is that the work this method delegates is `Hash#[]`, implemented
in C, which neither compiler can optimise.

**E5. Polymorphism: `double(x) = x + x`.**
[`zjit-calm.txt`](../captures/zjit-calm.txt),
[`zjit-choppy.txt`](../captures/zjit-choppy.txt),
[`yjit-choppy.txt`](../captures/yjit-choppy.txt),
[`zjit-choppy-stats.txt`](../captures/zjit-choppy-stats.txt),
[`yjit-choppy-stats.txt`](../captures/yjit-choppy-stats.txt).
Two programs, default settings. *Calm*: only Integers. *Choppy*: Integer,
Float, String, Array and Rational from the first call. In both, ZJIT
inlines `double` into the same caller, so the two plans compare like for
like.

- ZJIT, calm: one `GuardType … Fixnum` and one `FixnumAdd`.
- ZJIT, choppy: the profile shows five types, so the inlined body is a
  chain of `CondBranchHasType` tests, each followed by a
  `CCallWithFrame` to that class's `#+` (including `Integer#+`, no longer
  an inline add), and a final generic `Send` marked `polymorphic fallback`.
- YJIT, choppy: one block version per type: an inline fixnum add, plus
  calls to `Float#+`, `String#+`, `Array#+` and `Rational#+`.

Both statistics captures report `side_exit_count: 0`. Neither compiler
"bails out" here; both stop specialising and fall back to general calls.
The cost of polymorphism is the lost fast path, not exits.

## 7. Where no JIT helps

- **Waiting**: database, network and disk time are unaffected.
- **C code**: `Hash#[]`, JSON, OpenSSL and similar run as before (E4).
- **Allocation and garbage collection.**
- **Code that won't hold still**: values of many types at one site (E5),
  `send` with computed names, `method_missing`, `eval`. ZJIT also still
  delegates "a lot of begin/rescue and break/next-in-block to the
  interpreter" [3].

## 8. Status and direction

- **4.0 (2025-12-25)**: ZJIT is "developed as the next generation of
  YJIT" and "faster than the interpreter, but not yet as fast as YJIT";
  the release notes "advise against deploying it in production for now"
  and set the goal "to make ZJIT faster than YJIT and production-ready in
  Ruby 4.1" [4].
- **Why it was built**: "a more traditional 'textbook' compiler so it is
  easy for the community to contribute to" [1]; "raise the performance
  ceiling (bigger compilation unit size and SSA IR)" [2].
- **Direction stated by the team**: a "general-purpose method inlining
  facility" [2], which the 4.1 NEWS now lists [5]; block bodies are not
  yet inlined [3].
- **October 2026**: "ZJIT is probably as fast as or faster than YJIT" on
  Shopify's storefront renderer, in "a couple small regions"; "for a lot
  of benchmarks, we are neck and neck with YJIT. And there are definitely
  some where we are worse" [3].
- **4.1 previews**: "faster than YJIT on many benchmarks" but possibly
  "still slower than YJIT on larger benchmarks or applications" [5].

These statements are dated on purpose. The target moved from "on par" [1]
to "faster than YJIT" [4], and the latest sources are hedged [3][5].

## 9. Threats to validity

- **Preview build.** All captures use 4.1.0-preview1. Instruction names,
  value numbers (`v95`) and optimisation behaviour may differ in 4.1.0
  final; the repo will re-run every capture after its release.
- **Developer builds.** `--enable-yjit=dev --enable-zjit=dev` enables the
  disassembly and dump options. We compare *what* each compiler emits, not
  how fast it runs; no timings in this document come from these builds.
- **Settings.** Every capture uses default JIT settings except
  `yjit-sq-eager.txt`, which forces `--yjit-call-threshold=1` on purpose
  (E3). Forcing early compilation changes what YJIT emits (E2), so
  compare compilers only at the same settings.
- **Toy workloads.** E1–E3 and E5 are deliberately small. They isolate a
  mechanism; they do not predict application speed-ups. For that, see the
  team's own measurements [3][11].
- **One machine.** arm64 macOS only.
