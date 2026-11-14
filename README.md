# The Ceiling: Why Ruby 4.0 Needed a Second Compiler

Companion repo for the RubyConf 2026 talk (2026-11-21).

Ruby 4.0 ships two just-in-time compilers, **YJIT** and **ZJIT**. YJIT
already makes real Rails apps faster, so why did the Ruby core team build
a second one? This repo answers that with real compiler output: one
five-line method traced through both compilers, one extra method call
that only one of them can see through, and the team's own words on why
they did it.

> YJIT compiles Ruby a bit at a time, deciding as it goes; ZJIT plans a
> whole method at once, so it can see through small method calls and stop
> paying for them. That's the room Ruby needed to keep getting faster.

**Status: draft for RubyConf.** Every capture was made on **Ruby 4.1.0-preview1**.
Ruby 4.1.0 ships 2026-12-25; the captures will be re-run then.

## What's here

| Path | What |
|---|---|
| `talk/the-ceiling.html` | The slides (reveal.js). Open in a browser; press `s` for speaker notes. |
| `talk/the-ceiling.org` | The source of the slides, the notes, and the demo Ruby. |
| `talk/img/` | The swim diagrams. |
| `src/` | The demo programs. Generated from the talk file; don't edit by hand. |
| `captures/` | Raw compiler output every slide listing is cut from. |
| `bin/capture` | Re-runs the captures. |
| `bin/check` | Checks that every line on a slide exists in a capture, and more. |
| `bin/export` | Re-exports the slides. |
| `docs/` | The design and build plan for this repo. |
| `analysis/yjit-vs-zjit.md` | The formal comparison: how each JIT works, every experiment, status and limits. |
| `references/README.md` | Annotated sources, with the exact quotes used and where. |


## Reproduce it

You need Ruby 4.1.0-preview1 built with both JITs in developer mode
(needed for `--yjit-dump-disasm`), plus activesupport:

```sh
RUBY_CONFIGURE_OPTS="--enable-yjit=dev --enable-zjit=dev" asdf install ruby 4.1.0-preview1
gem install activesupport          # from this directory, so .tool-versions applies
bin/check env                      # tells you exactly what's missing, if anything
bin/capture                        # writes captures/*.txt
bin/check                          # every check should print "ok"
```

Building Ruby with YJIT/ZJIT needs a Rust toolchain on your PATH. If the
build fails while installing bundled gems with a `libyaml` error, install
libyaml (`brew install libyaml` on macOS) and retry.

Try it on your own code:

```sh
ruby -e 'puts RubyVM::InstructionSequence.of(method(:m)).disasm'   # bytecode
ruby --zjit --zjit-dump-hir   your_hot_path.rb                      # ZJIT's plan
ruby --zjit --zjit-stats      your_hot_path.rb                      # what it did
```

## Presenting

- Present `talk/the-ceiling.html` in a browser (press `s` for the speaker
  view with notes and timer).
- The one live demo ("How Ruby runs your code") runs from Emacs: open
  `talk/the-ceiling.org` and `C-c C-c` the `ruby -r ./distance` block. It
  tangles `src/` first and runs under the pinned Ruby via asdf.
- Don't present the `.org` file with org-tree-slide or org-present: they
  show the `#+begin_notes` speaker notes on the projector.
- `bin/export` re-exports the HTML. It uses a clean Emacs and installs
  org-re-reveal into `.emacs-deps/` (git-ignored); your own config is not
  touched.

## Licence

Code (`src/`, `bin/`): MIT, see `LICENSE`. Talk, diagrams and prose:
CC BY 4.0, see `LICENSE-CONTENT`.
