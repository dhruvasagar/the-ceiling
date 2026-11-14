# References

Every claim in the talk and the analysis that isn't backed by a capture in
`../captures/` rests on one of these. All links were checked and all
quotes copied from the source text on **2026-11-14**. Each entry lists the
exact words used and where they're used.

## The ZJIT team

[1] Max Bernstein. *ZJIT has been merged into Ruby.* Rails at Scale,
2025-05-14. https://railsatscale.com/2025-05-14-merge-zjit/

- "The main difference is that the team is making the intentional choice
  to build a more traditional “textbook” compiler so it is easy for the
  community to contribute to." (talk: *In the ZJIT team's words*, notes;
  analysis §8)
- "Instead of using lazy basic block versioning (LBBV) to profile types, it
  reads historical type information from the profiled interpreter" and
  "Instead of compiling one basic block at a time, it compiles one entire
  method at a time" (talk: *Why it's a ceiling*, notes; analysis §2, §3)
- "while YJIT’s architecture allows for easy interprocedural type-based
  specialization, ZJIT’s architecture gives more code at once to the
  optimizer." (talk: *At the turn buoy*, notes; analysis §6 E3)
- "we will improve ZJIT until it is on par (features and performance) with
  YJIT." (analysis §8)

[2] Max Bernstein. *ZJIT is now available in Ruby 4.0.* Rails at Scale,
2025-12-24. https://railsatscale.com/2025-12-24-launch-zjit/

- "we want to both raise the performance ceiling (bigger compilation unit
  size and SSA IR) and encourage more outside contribution (by becoming a
  more traditional method compiler)." (talk: *In the ZJIT team's words*, on the
  slide; analysis §8)
- "It’s faster than the interpreter, but not yet as fast as YJIT. Yet."
  (talk: *In the ZJIT team's words*, notes; analysis §8)
- "We only have a limited inliner that inlines constants, self, and
  parameters. In the fullness of time, we will add a general-purpose method
  inlining facility." (talk: *In the ZJIT team's words*, notes; analysis §8)
- "if your method call patterns change significantly after your code has
  been compiled, we will frequently side-exit into the interpreter."
  (analysis §3, §6 E5)

[3] Max Bernstein. *ZJIT is now as fast as YJIT.* Rails at Scale,
2026-10-09. https://railsatscale.com/2026-10-09-zjit-is-now-as-fast-as-yjit/

- "ZJIT is probably as fast as or faster than YJIT." Measured on Shopify's
  storefront renderer in "a couple small regions". (talk: *What it means
  for Ruby*, notes; analysis §8)
- "For a lot of benchmarks, we are neck and neck with YJIT. And there are
  definitely some where we are worse." (analysis §8)
- "YJIT takes 125MiB and ZJIT takes 101MiB." (analysis §4)
- "we generate more code (less precise than LBBV and more versions) and
  probably bigger code" (talk: *Measured: the ZJIT team's results, and ours*)
- "we do not yet support inlining the blocks themselves" and "Right now we
  delegate a lot of begin/rescue and break/next-in-block to the
  interpreter." (analysis §7, §8)

[14] Jacob Denbeaux. *How ZJIT removes redundant object loads and stores.*
Rails at Scale, 2026-03-18.
https://railsatscale.com/2026-03-18-how-zjit-removes-redundant-object-loads-and-stores/

- "ZJIT takes an average of 2ms per iteration on this benchmark, while
  YJIT takes an average of 5ms." (the setivar benchmark) (talk: *Measured: the
  ZJIT team's results, and ours*)
- "ZJIT is over twice as fast as YJIT for repeated instance variable
  assignment" (talk: *Measured: the ZJIT team's results, and ours*, notes)
- "we're now beginning to see the design differences between YJIT and
  ZJIT manifest themselves in performance divergences" (analysis §8)

[15] Aaron Patterson. *A new Register Allocator for ZJIT.* Rails at Scale,
2026-05-27. https://railsatscale.com/2026-05-27-a-new-register-allocator-for-zjit/

- "YJIT compiles one basic block at a time, so it never has the full
  picture of the function anyway" (talk: *Measured: the ZJIT team's results, and ours*,
  depth note; analysis §2)

[16] Max Bernstein. *The inliner is yielding benefits for ZJIT.* Rails at
Scale, 2026-07-28. https://railsatscale.com/2026-07-28-the-inliner-is-yielding-benefits/

- "ZJIT chooses to get call context by inlining" (on blocks; YJIT relies
  on methods annotated for it) (analysis §8)

## Ruby itself

[4] Ruby core team. *Ruby 4.0.0 Released.* ruby-lang.org, 2025-12-25.
https://www.ruby-lang.org/en/news/2025/12/25/ruby-4-0-0-released/

- "ZJIT is a new just-in-time (JIT) compiler, which is developed as the
  next generation of YJIT." (talk: *What it means for Ruby*, notes)
- "As of Ruby 4.0.0, ZJIT is faster than the interpreter, but not yet as
  fast as YJIT."
- "Our goal is to make ZJIT faster than YJIT and production-ready in Ruby
  4.1." (talk: *What it means for Ruby*, notes; analysis §8)
- "advise against deploying it in production for now." (analysis §8)

[5] Ruby core team. *NEWS for Ruby 4.1.0* (ruby/ruby master, read
2026-11-14). https://github.com/ruby/ruby/blob/master/NEWS.md

- "ZJIT is now faster than YJIT on many benchmarks, but we expect that ZJIT
  can be still slower than YJIT on larger benchmarks or applications as of
  Ruby 4.1.0 preview releases." (talk: *What it means for Ruby*, notes;
  analysis §8)
- "Method inlining: small Ruby methods, including methods that yield to a
  block, are inlined into their callers" (analysis §3, §8)

[6] Ruby core team. *Ruby 4.1.0-preview1 Released.* ruby-lang.org,
2026-10-12. https://www.ruby-lang.org/en/news/2026/10/12/ruby-4-1-0-preview1-released/

- The version every capture in this repo was made with. (Its JIT section
  lists only a YJIT change; ZJIT's 4.1 changes are in NEWS [5].)

[7] Ruby core team. *ZJIT* documentation, `doc/jit/zjit.md`.
https://github.com/ruby/ruby/blob/master/doc/jit/zjit.md

- "ZJIT is a method-based just-in-time (JIT) compiler for Ruby. It uses
  profile information from the interpreter to guide optimization in the
  compiler." (analysis §3)
- HIR: "High-level (Ruby semantics) graph representation in static
  single-assignment (SSA) form". Side exit: "Exit from JIT code back to
  interpreter". (analysis §3)
- `--zjit-call-threshold` "(default: 30)", `--zjit-num-profiles` "(default:
  5)". (analysis §5)

[8] Ruby core team. *YJIT* documentation, `doc/jit/yjit.md`.
https://github.com/ruby/ruby/blob/master/doc/jit/yjit.md

- "It lazily compiles code using a Basic Block Versioning (BBV)
  architecture." (analysis §2)

## Source code and documentation (read 2026-11-14)

[12] Ruby core team. *YJIT* documentation and source, ruby/ruby master.
- `doc/jit/yjit.md` line 200: `--yjit-call-threshold` "defaults to 30, and
  it's then increased to 120 when the number of ISEQs in the process
  reaches 40,000." (talk: *25 compiles, or one*, depth note)
  https://github.com/ruby/ruby/blob/master/doc/jit/yjit.md
- `yjit/src/options.rs`: `max_versions: 4` (default number of versions
  of a block). (talk: *In the ZJIT team's words*, notes)
  https://github.com/ruby/ruby/blob/master/yjit/src/options.rs
- `vm_insnhelper.c`, `vm_opt_minus` (line 7094): checks both operands are
  fixnums (`FIXNUM_2_P`) and that `-` isn't redefined before its fast path,
  on every execution. (talk: *The bytecode*)
  https://github.com/ruby/ruby/blob/master/vm_insnhelper.c
- `yjit/src/backend/ir.rs`: YJIT's low-level IR inside its code generator.
  (talk: *Why it's a ceiling*, Q&A note)
  https://github.com/ruby/ruby/blob/master/yjit/src/backend/ir.rs

[13] Rails core team. `actionpack/lib/action_controller/metal/strong_parameters.rb`,
Rails v8.1.1, line 294: `@parameters = parameters.with_indifferent_access`.
Rails `params` is built on `HashWithIndifferentAccess`. (talk: *Race day:
params*)
https://github.com/rails/rails/blob/v8.1.1/actionpack/lib/action_controller/metal/strong_parameters.rb

## Research behind YJIT

[9] Maxime Chevalier-Boisvert and Marc Feeley. *Simple and Effective Type
Check Removal through Lazy Basic Block Versioning.* ECOOP 2015 (arXiv
2014-11-03). https://arxiv.org/abs/1411.0352

- Introduces lazy basic block versioning: it "lazily generates
  type-specialized versions of basic blocks on-the-fly while propagating
  context-dependent type information". "On average, 71% of type tests are
  eliminated, yielding speedups of up to 50%." (analysis §2)

[10] Maxime Chevalier-Boisvert, Noah Gibbs, Jean Boussier, Si Xing (Alan)
Wu, Aaron Patterson, Kevin Newton, John Hawthorn. *YJIT: a basic block
versioning JIT compiler for CRuby.* VMIL 2021, 2021-10-19.
https://doi.org/10.1145/3486606.3486781

- YJIT's design paper: LBBV inside CRuby; "speedups from 15% to 19% on
  sizeable benchmarks based on real-world software." (analysis §2)

[11] Maxime Chevalier-Boisvert, Takashi Kokubun, Noah Gibbs, Si Xing
(Alan) Wu, Aaron Patterson, Jemma Issroff. *Evaluating YJIT’s Performance
in a Production Context: A Pragmatic Approach.* MPLR 2023, 2023-10-19.
https://doi.org/10.1145/3617651.3622982

- The paper `doc/jit/yjit.md` asks people citing YJIT to use. (analysis §2)

## Where the sources disagree

The 4.1 target moved, and the sources say so in different words: "on par
(features and performance) with YJIT" (2025-05 [1]); "faster than YJIT and
production-ready in Ruby 4.1" (4.0.0 release notes [4]); "faster than YJIT
on many benchmarks" but possibly "still slower… on larger benchmarks or
applications" (4.1 NEWS [5]); "probably as fast as or faster than YJIT" on
one production workload in small regions (2026-10 [3]). The talk and the
analysis quote them with dates instead of picking one.

On inlining: 4.0 had only "a limited inliner" [2]; the 4.1 NEWS lists
general method inlining including methods that yield [5]; the October post
says block bodies themselves are not yet inlined [3].
