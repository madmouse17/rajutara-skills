---
name: rajutara-dev
description: "Build, test and extend the rajutara Rust workspace (apparel CAD: PDS, Grading, Marker, Cut Plan). Use when changing code under crates/ of the rajutara repo - running the gates, the one-binary-per-crate test layout, finding which crate owns something, or adding a tool, command, pane, file field or translated string under the Optitex-names rule."
---

# rajutara-dev

Work in a checkout of `rajutara` (workspace root has `Cargo.toml`, `AGENTS.md`, `GLOSSARY.md`). Every path below is relative to that root. Read `AGENTS.md` first; it binds people and agents alike. Before touching the model, also read the clean-room rules in the `rajutara-clean-room` skill. Written for rajutara 1.5.0.

## Read order

1. `AGENTS.md`, `GLOSSARY.md` (its words are the Rust type and module names), `CONTRIBUTING.md`.
2. `docs/adr/` (settled decisions; never edit an ADR, supersede it with a new one).
3. `docs/spec/00-overview.md` §4 (layout) and §5 (cross-cutting rules), then the spec of the workspace you touch: `01-core-model.md`, `02-pds.md`, `03-grading.md`, `04-marker.md`, `05-cutplan.md`, `07-ui-shell.md`.
4. `docs/parity-checklist.md` (what matches Optitex 15 and what does not) and `ROADMAP.md` (what is not built). Open items go there or into an issue, never into code comments.
5. `CHANGELOG.md` `## [Unreleased]` for what changed since the last release.

## Toolchain and gates

Stable Rust pinned in `rust-toolchain.toml`, edition 2024, resolver 3, installed through `mise install`. Linux (Ubuntu 24.04) is the reference platform.

```sh
cargo fmt --all --check
cargo clippy --workspace --all-targets -- -D warnings
LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1280x800x24" cargo test --workspace
cargo deny check                       # licences, advisories, bans, duplicate versions
scripts/test-scripts.sh                # only when you touch scripts/ or the budgets
```

Rules for claiming "done" (`AGENTS.md`): run the four commands above and paste the result; if you did not run one, say "not verified".

Crate-scoped loop while iterating: `cargo test -p rajutara-core`, `cargo clippy -p rajutara-io --all-targets -- -D warnings`. UI tests open real windows, so a plain `cargo test --workspace` without a display fails; use the `xvfb-run` form.

### Test layout: one integration binary per crate

Every crate merges its integration tests into one binary so the test build links once: `crates/<crate>/tests/all/main.rs` holds one `mod <file>;` line per test file in `crates/<crate>/tests/all/`, plus shared helpers in `tests/all/support/` or `tests/all/common/`. A new test file is `crates/<crate>/tests/all/<name>.rs` **and** its `mod <name>;` line in `main.rs`; a file without that line is never compiled. Never add a new top-level `tests/<name>.rs` (each one is another binary to link). The only exception is `crates/rajutara-nest/tests/nest_env_independent.rs`, a binary of its own because it changes the process environment.

```sh
cargo test -p rajutara-pds --test all notch_slit        # one module of the merged binary (filter by path)
cargo test -p rajutara --test all optitex_names         # the names rule, below
```

`insta` snapshots of the merged binary are named after it: `crates/rajutara-io/tests/all/snapshots/all__native__style_json_shape.snap`.

### Faster local builds

- `[profile.dev] debug = "line-tables-only"` in `Cargo.toml`: debug builds keep file and line in backtraces but no variable info, which makes `target/debug` far smaller and links faster. Need a debugger with locals? `CARGO_PROFILE_DEV_DEBUG=true cargo test -p <crate>`.
- Linker: `mold` is optional and set per machine, never in the repo. In `~/.cargo/config.toml`: `[target.x86_64-unknown-linux-gnu]` `rustflags = ["-C", "link-arg=-fuse-ld=mold"]`. Missing `ld.mold` at link time means `mold` is not on `PATH`.
- Runner: `cargo nextest run -p rajutara-pds` (cargo-nextest, optional) runs every test in its own process. CI runs `cargo test`, so a test must still pass there: keep the i18n mutex rule below even if nextest hides the race.

Release and budgets (ADR-0006/0009, spec `00-overview.md` §5.7):

```sh
cargo build --release -p rajutara
scripts/check-budgets.sh size target/release/rajutara     # <= 40 MB
scripts/check-budgets.sh linux target/release/rajutara    # runs --smoke under Xvfb + llvmpipe
```

Windows builds (windowing, dialogs, file system, dependencies) are cross-built and checked under Wine by the maintainer's rajutara-windows-tools, outside this repository (`CONTRIBUTING.md`). Say in the pull request when a change touches that code. Never use `tokio` or any async runtime (`deny.toml` bans them).

Disk: parallel builds inflate `target/debug`. Run `df -h /` before a wave; below 20 GB free delete `target/debug/incremental`.

## Crate map

Dependency direction, one way: `rajutara-core <- rajutara-io <- rajutara-ui <- {rajutara-pds, rajutara-grading, rajutara-nest, rajutara-cutplan} <- rajutara`; `rajutara-cutplan` also uses `rajutara-nest`.

| Crate | Owns | Entry points |
|---|---|---|
| `rajutara-core` | Model, geometry, grading derivation, undo, units, validation. No UI, no I/O. | `crates/rajutara-core/src/lib.rs`, `model/`, `geom/`, `grading.rs`, `history.rs`, `validate.rs`, `units.rs`, `marker.rs`, `cutplan.rs` |
| `rajutara-io` | `.rjx/.rjm/.rjc`, DXF, RUL, HPGL/2, PDF, CSV, Excel `.xlsx` | `crates/rajutara-io/src/lib.rs`, `dxf/`, `native/`, `plot/`, `rul.rs`, `report.rs`, `xlsx.rs` |
| `rajutara-ui` | Shell: docking, canvas, palette, shortcuts, themes, i18n, jobs, `--smoke` | `crates/rajutara-ui/src/module.rs` (the `Module` trait), `layout.rs`, `shell.rs`, `smoke.rs`, `canvas/`, `widgets/` |
| `rajutara-pds` | PDS workspace: tools, ops, panes, menus, plot | `src/actions.rs`, `tools/registry.rs`, `ops/`, `panes/`, `plot/`, `import/` |
| `rajutara-grading` | Grading workspace: size table, rules, graded nest, export | `src/export.rs`, `size_table/`, `rule_table.rs`, `nest_view.rs`, `tools/` |
| `rajutara-nest` | Marker workspace and the headless nesting engine | `src/engine/` (no egui types), `marker/` (clusters, cut order, flaws, holes), `output/`, `report.rs` |
| `rajutara-cutplan` | Order, lay solver, Cut Order, reports, the Create New wizard | `src/solve.rs`, `apply.rs`, `nesting.rs`, `cut_order.rs`, `report.rs`, `rolls.rs` |
| `rajutara` | Binary: `args.rs`, `modules.rs`, `main.rs`; the end-to-end, CLI and names tests; the sample | `crates/rajutara/tests/all/e2e_workflow.rs`, `crates/rajutara/tests/all/optitex_names.rs`, `examples/tshirt_sample.rs` |

Other places: `fixtures/` (budget fixtures `style-100.rjx`, `marker-1000.rjm`), `samples/kaos-lengan-pendek/` (sample outputs), `scripts/`, `packaging/`, `docs/parity-checklist.md` (feature comparison with Optitex 15).

## Conventions that reviewers check first

- Lengths are `f64` millimetres, X right, Y up, angles in radians counter-clockwise. Display units are never stored. Tolerances are named constants (`EPS_MM` in `crates/rajutara-core/src/lib.rs`, `WORKING_TOLERANCE_MM` and friends in `crates/rajutara-core/src/geom/mod.rs`).
- Library crates: no `unwrap`, `expect` or `panic!` outside tests; errors are `thiserror` enums. `rajutara-core` has no UI or I/O dependency.
- Every public type in `rajutara-core` derives `Debug, Clone, PartialEq, serde::Serialize, serde::Deserialize`. Optional fields use `#[serde(default, skip_serializing_if = ...)]`.
- Long work runs on `std::thread` with `std::sync::mpsc`; the UI polls (`crates/rajutara-ui/src/jobs.rs`).
- Same input and settings give byte-identical output. The only exception is the UTC stamp in export headers (`rajutara_io::utc_now_stamp`).
- Tests pin behaviour and invariants, not incidental formatting. Use `insta` snapshots for DXF/HPGL output (`crates/rajutara-io/tests/all/snapshots/`), `proptest` for geometry invariants, `egui_kittest` for UI (drive by AccessKit label, never pixel position). Long benchmarks are `#[ignore]` and run in release.
- Comments explain why. No TODO or FIXME in committed code.
- New dependency: one-line justification, licence on the `deny.toml` allow-list, prefer crates already in `Cargo.lock`.
- One owner per file per wave. If you need a file you do not own, report `needs-change: <path> - <why>`.
- Never `git commit` or `git push` unless the user asks.

## The Optitex-names rule

An Operator finds a tool under the name the Optitex help uses, so every action label is that name. `crates/rajutara/tests/all/optitex_names.rs` reads the Fluent files of `pds`, `nest`, `grading`, `ui` and `cutplan` and fails when:

- an action message has no `.optitex` attribute (every id in `rajutara_pds::actions::ALL_IDS`, every `nest-act-*` and `grading-*` id of `ui/actions.rs`);
- the English label differs from its `.optitex` value (a trailing `…` on a dialog item and a trailing ` window` on a pane are ignored), unless the id is in `EXCEPTIONS` with a one-line reason; an exception whose label already matches is stale and fails too;
- the `id` file does not repeat the English `.optitex` value word for word (the Indonesian label translates, the attribute does not);
- a `.menu` caption equals its label, lacks a distinct Indonesian `.menu`, or is not pinned in `MENU_CAPTIONS`;
- a `*-prompt-*` message is not a sentence (capital first letter, full stop at the end) in either language.

```ftl
pds-tool-notch = Notch Tool
    .optitex = Notch Tool
```

The `.optitex` value comes from public Optitex documentation only (cite it in the spec, `rajutara-clean-room`). Keys follow the public Optitex lists too: `crates/rajutara-pds/tests/all/optitex_keys.rs` pins the PDS keys and refuses a key bound twice; the Marker map is checked inside `crates/rajutara-nest/src/ui/actions.rs`. Do not invent a key; check `docs/spec/07-ui-shell.md` §6.

## Recipes

### Add a field to the model

1. Add it to the struct in `crates/rajutara-core/src/model/` (or `marker.rs`, `cutplan.rs`) with `#[serde(default, skip_serializing_if = ...)]` so old files still load and a document without it writes no new key.
2. A field holding ids (`PointId`, `InternalLineId`, ...) must be renumbered in `Piece::remap_ids` and counted by the id checks, or paste and merge break it. Check it in `crates/rajutara-core/src/validate.rs`: add an `IssueCode` variant if a new invariant exists.
3. Format version: an optional field keeps format 2, as 1.5.0 did for `Marker::clusters`, `cut_order`, `flaws`, `bump_lines`, `texts`, `Vertex::name` and the new Piece and Style fields. An older build then opens the file but drops the field on re-save; say so in `CHANGELOG.md`. Bump `CURRENT_VERSION` and add to `MIGRATIONS` in `crates/rajutara-io/src/native/migrate.rs` only when an older build would misread the file or must refuse it; the chain is proven by `crates/rajutara-io/tests/fixtures/native/v1/`.
4. Update `docs/spec/01-core-model.md` and `CHANGELOG.md`. A new domain term goes into `GLOSSARY.md` first.
5. Tests: `crates/rajutara-core/tests/all/style_json.rs`, `crates/rajutara-core/tests/all/validate_props.rs` and `crates/rajutara-io/tests/all/native.rs`. The JSON shape is pinned by `crates/rajutara-io/tests/all/snapshots/all__native__style_json_shape.snap`; review the snapshot diff, never blindly accept.

### Add an undoable edit (command)

Every document mutation goes through `Document::execute` with a `Command<D>` (`crates/rajutara-core/src/history.rs`). Most are an `Edit { label, f }` closure. The `label` is a Fluent id of the form `cmd-...` that must exist in the crate's `en` and `id` `.ftl`. In PDS, wrap the closure with `edit(label, |style| ...)` from `crates/rajutara-pds/src/ops/mod.rs` and use `with_piece` so protected pieces are refused and snapshots stay shallow (`Arc::make_mut`). A command that would add a validation `Error` returns `CommandError::Invalid`. One Operator gesture is one undo step.

### Add a PDS tool or command

1. Write the UI-free edit in `crates/rajutara-pds/src/ops/<area>.rs`; unit-test it there.
2. Write the gesture in `crates/rajutara-pds/src/tools/<name>.rs`: implement `ToolMachine` (`tools/machine.rs`) and export `pub const ROWS: &[ActionRow]`. `ActionKind` is `Tool`, `Command`, `View` or `Form`; see `tools/notch.rs` for a full tool and `tools/piece_cmds.rs` for plain commands.
3. Register the module in `crates/rajutara-pds/src/tools/mod.rs` and add `crate::tools::<name>::ROWS,` on its own line in `rows()` of `crates/rajutara-pds/src/tools/registry.rs`.
4. Add the id (`pds-tool-<kebab>`, `pds-cmd-<kebab>`, `pds-view-<kebab>`) to `ALL_IDS` in `crates/rajutara-pds/src/actions.rs`; give it the Optitex key if the public list has one (no new key without checking conflicts).
5. Add the label **with its `.optitex` attribute** to `crates/rajutara-pds/i18n/en/rajutara_pds.ftl` **and** `crates/rajutara-pds/i18n/id/rajutara_pds.ftl`, plus a `pds-prompt-...` sentence for each tool step. `crates/rajutara-pds/tests/all/ids_in_catalog.rs` reads every `pds-` and `cmd-` literal in `src/` as a message id; a partial prefix literal (an egui id salt such as `"pds-..."`) breaks it.
6. Tests: a behaviour test in `crates/rajutara-pds/tests/all/<name>.rs` with its `mod` line; `crates/rajutara-pds/tests/all/registry.rs` and `crates/rajutara/tests/all/optitex_names.rs` stay green. For menu or context-menu tests in the kittest harness, register the module's actions and catalog in the shell first (`crates/rajutara-pds/tests/all/support/harness.rs`).
7. Update `docs/spec/02-pds.md` §5 and `docs/parity-checklist.md`.

### Add a pane or workspace

Pane ids live in `rajutara_ui::layout::panes` (`crates/rajutara-ui/src/layout.rs`). Add the `PaneId`, put it in the module's default layout (`layout::pds()`, `grading()`, `marker()`, `cutplan()`), draw it from `Module::pane_ui`, title it in `Module::pane_title`, and add a toggle row (`pane_row!` in `crates/rajutara-pds/src/panes/mod.rs`). A workspace is a `Module` (`crates/rajutara-ui/src/module.rs`) registered in `crates/rajutara/src/modules.rs`; panes draw from plain data and return intents, they do not touch the document directly.

### Add a translated string

`fl!` over `i18n-embed`. Each crate with UI has `i18n.toml`, `i18n/en/<crate>.ftl` (source) and `i18n/id/<crate>.ftl`. Ids are `<crate>-<area>-<name>`. Update both files in the same change; parity tests fail otherwise (`parity_problems` in `crates/rajutara-ui/src/i18n.rs`). Format numbers with `rajutara_core::units`, pass them as string arguments. The i18n loader is process-global: a test that switches language must serialise with a mutex or it flips labels under parallel tests.

### Add a file format or exporter

Put it in `crates/rajutara-io/src/`, return `Result<_, IoError>`, report every skipped or approximated entity as an `ImportIssue` (see `rajutara-io` skill), write through `write_atomic`, snapshot-test the output, and add an original fixture under `crates/rajutara-io/tests/fixtures/`. `crates/rajutara-io/src/xlsx.rs` is the smallest complete example: deterministic bytes, Excel limits refused with `IoError::Refused`.

## Final checklist

- Gates run and pasted (or "not verified").
- `CHANGELOG.md`, the touched spec, `docs/parity-checklist.md` and `GLOSSARY.md` updated.
- `en` and `id` strings both present; every new action has its `.optitex` attribute in both files.
- New test files have their `mod` line in `tests/all/main.rs`.
- No Optitex file, string or screenshot used as a source; no GPL code ported (`rajutara-clean-room`).
