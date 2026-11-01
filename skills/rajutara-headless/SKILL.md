---
name: rajutara-headless
description: "Drive rajutara without a person at the screen - the --smoke self-check under Xvfb, the tshirt_sample example that drafts, grades, nests and plots a whole job, the end-to-end test, and scripting the library crates or the zip+JSON documents from CI, scripts or agents. Use when verifying a build, producing sample outputs, or automating conversions."
---

# rajutara-headless

Two headless surfaces exist: the real binary with `--smoke` (needs a virtual display), and the library crates (need nothing). There is no CLI for conversions; automation means a small Rust program against the crates or the `tshirt_sample` pattern. Run everything from the repo root of an `rajutara` checkout.

## The binary

```text
rajutara [--lang en|id] [FILE...]    open the shell, then FILEs (.optx .optm .optc .dxf)
rajutara --version                   "rajutara <version> (<git hash>, <target>)", exit 0
rajutara --smoke [FILE]              open the real window, render 60 frames, print one JSON line, exit 0
```

Parsing is in `crates/rajutara/src/args.rs`. Exit codes: 0 success; 1 for usage errors (unknown flag, `--lang` other than `en`/`id`, a `--smoke FILE` that cannot be opened, with no JSON on stdout); 2 for a window or OpenGL failure (message on stderr). The CLI contract is tested in `crates/rajutara/tests/cli.rs`.

### `--smoke`

```sh
cargo build --release -p rajutara
LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1280x800x24" target/release/rajutara --smoke
LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1280x800x24" target/release/rajutara --smoke fixtures/style-100.optx
```

One line of JSON, for example:

```json
{"frames":60,"first_frame_ms":56.5,"max_frame_cpu_ms":0.328,"warmup_ms":0.000,"peak_rss_kb":122392,"gl_renderer":"llvmpipe (LLVM 21.1.8, 256 bits)","gl_version":"4.5 (Core Profile) Mesa 26.0.8-1ubuntu0.3"}
```

Read `frames` (must be >= 60), `first_frame_ms`, `max_frame_cpu_ms`, `peak_rss_kb`, `gl_renderer`, `gl_version`. Budgets are decided by `scripts/check-budgets.sh` (ADR-0006, ADR-0009):

```sh
scripts/check-budgets.sh size target/release/rajutara       # <= 40 MB
scripts/check-budgets.sh linux target/release/rajutara      # runs --smoke 3 times, enforces RSS and frame time
scripts/check-budgets.sh json-shape smoke.json              # a saved line is well formed (also used under Wine)
BUDGET_FIXTURES=on scripts/check-budgets.sh linux target/release/rajutara   # also the 100-piece and 1000-piece fixtures
scripts/test-scripts.sh                                     # self-test of the budget scripts
```

Limits: idle RSS <= 150 MB, 100-piece Style <= 400 MB, 1000-piece Marker <= 8 ms CPU per frame; cold start over 1.5 s only warns. The same line decides a Windows 7 build under Wine (`scripts/build-win7.sh --test rajutara`, Docker image `docker/win7-cross.Dockerfile`).

Needed packages on Ubuntu 24.04: `xvfb mesa-utils libgl1 libgl1-mesa-dri libegl1 libxkbcommon-x11-0 libxcursor1 libxi6 libxrandr2` (see the README build section). CI runs it with `LIBGL_ALWAYS_SOFTWARE=1` so Mesa llvmpipe renders without a GPU.

## The sample job: `tshirt_sample`

```sh
cargo run --release -p rajutara --example tshirt_sample -- out/
```

No window opens. In `crates/rajutara/examples/tshirt_sample.rs` it: drafts a four-piece T-shirt Style for Base Size M, grades it to S, M, L, XL, validates (`validate_style`, refusing on errors) and checks the grading; saves `.optx`; embeds it in a Marker (one Bundle per size on 1800 mm Single Jersey, buffer 5 mm); auto-nests with `Stop::Time(15 s)` and `seed: 1`; checks 0 overlaps; then writes everything and reloads it to prove equality. Outputs, identical to `samples/kaos-lengan-pendek/`:

| File | Writer |
|---|---|
| `kaos-lengan-pendek.optx` | `rajutara_io::save_style` |
| `kaos-lengan-pendek-marker.optm` | `save_marker` |
| `kaos-lengan-pendek.dxf` + `.rul` | `rajutara_grading::export::run_export` with `GradingExport::RuleFile` |
| `kaos-lengan-pendek-marker.pdf` (A0), `-marker.plt` (HPGL/2) | `rajutara_nest::output::plot::plot_marker` |
| `kaos-lengan-pendek-marker-report.csv` | `rajutara_nest::report::write_csv_report` |
| `kaos-lengan-pendek-pieces-M.pdf` (A4 tiles) | `rajutara_pds::plot::job::plot_job` + `rajutara_io::plot_pdf` |

It prints `draft: ...`, `marker: ... efficiency ... length ... conflicts` and `reload: ...` lines and returns an error (non-zero exit) when validation, fit or round trip fails. Copy it as the template for your own pipeline: replace `tee_style()` with `rajutara_io::import_dxf(..)` (see `rajutara-io`), keep the validate, nest, verify, write, reload shape.

## End-to-end test

`crates/rajutara/tests/e2e_workflow.rs` runs the operator workflow headless through the same public API the workspaces call: DXF + RUL import, notch edit through `History`, grading, ASTM export and re-import, a three-size Marker, auto-nesting, HPGL/2 and PDF plots, a Cut Plan solved and reported to CSV and PDF. Artifacts land in `target/e2e/artifacts`.

```sh
cargo test -p rajutara --test e2e_workflow -- --nocapture          # prints "E2E ..." lines; budgets printed, not asserted
cargo test -p rajutara --release --test e2e_workflow -- --include-ignored   # budgets asserted, includes the 300-piece nest
```

## Scripting the library

Add a binary or example to the `rajutara` crate (it already depends on every library crate; `crates/rajutara/Cargo.toml`) rather than a new workspace. Skeleton:

```rust
use rajutara_io::{import_dxf, DxfImportOptions, save_style};
let (style, issues) = import_dxf(Path::new("in/shirt.dxf"), &DxfImportOptions::default())?;
for i in &issues { eprintln!("{:?} {}: {}", i.severity, i.location, i.message); }
let errors = rajutara_core::validate_style(&style).into_iter()
    .filter(|i| i.severity == rajutara_core::Severity::Error).count();
if errors > 0 { return Err(format!("{errors} validation error(s)").into()); }
save_style(&style, Path::new("out/shirt.optx"))?;
```

Rules: always surface every `ImportIssue`; validate before saving; never use `unwrap` on user data; pass `created: utc_now_stamp()` only for real exports (tests keep the epoch default so output is byte-stable); for determinism use `Stop::Iterations(n)` and a fixed `seed` (see `rajutara-nesting`).

## Without Rust: read the documents

`.optx`, `.optm`, `.optc` are zip files with `manifest.json` and `document.json` (format 2). A script can inspect them:

```sh
unzip -p samples/kaos-lengan-pendek/kaos-lengan-pendek.optx manifest.json
unzip -p samples/kaos-lengan-pendek/kaos-lengan-pendek.optx document.json | jq '.pieces | length'
unzip -p samples/kaos-lengan-pendek/kaos-lengan-pendek-marker.optm document.json | jq '[.pieces[] | select(.pose == null)] | length'   # instances still in the Piece Bar
```

Reading is safe; **writing** documents by hand skips validation, id allocation and the read-back check of `save_*`. Write through the crates, then reload to verify. Same input and settings give byte-identical files; export headers carry a UTC timestamp, so only that line differs between two exports.

## Checks an agent should run after a change

1. `cargo build --release -p rajutara` then the `--smoke` line under `xvfb-run`: `frames` is 60 and the exit code is 0.
2. `cargo run --release -p rajutara --example tshirt_sample -- target/sample` exits 0 and the `marker:` line shows 0 conflicts.
3. List `target/sample` and compare with the output table above; every file must exist and `reload:` must print equal documents. Marker and DXF files carry a timestamp or a time-limited nesting result, so compare those only under fixed options.
4. Report exactly what ran; "not verified" for anything that did not.
