---
name: optirust-dev
description: "Build, test and extend the optirust Rust workspace (apparel CAD: PDS, Grading, Marker, Cut Plan). Use when changing code under crates/ of the optirust repo - running the gates, finding which crate owns something, or adding a tool, command, pane, file field or translated string."
---

# optirust-dev

Work in a checkout of `optirust` (workspace root has `Cargo.toml`, `AGENTS.md`, `GLOSSARY.md`). Every path below is relative to that root. Read `AGENTS.md` first; it binds people and agents alike. Before touching the model, also read the clean-room rules in the `optirust-clean-room` skill.

## Read order

1. `AGENTS.md`, `GLOSSARY.md` (its words are the Rust type and module names), `CONTRIBUTING.md`.
2. `docs/adr/` (settled decisions; never edit an ADR, supersede it with a new one).
3. `docs/spec/00-overview.md` §4 (layout) and §5 (cross-cutting rules), then the spec of the workspace you touch: `01-core-model.md`, `02-pds.md`, `03-grading.md`, `04-marker.md`, `05-cutplan.md`, `07-ui-shell.md`.
4. `docs/plans/` holds the implementation plans. Open items go there, never in code comments.
5. Rust style: the project skill `.omp/skills/rust-skills/SKILL.md` (priorities: ownership, error handling, API design, memory, performance).

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

Crate-scoped loop while iterating: `cargo test -p optirust-core`, `cargo clippy -p optirust-io --all-targets -- -D warnings`. UI tests open real windows, so a plain `cargo test --workspace` without a display fails; use the `xvfb-run` form.

Release and budgets (ADR-0006/0009, spec `00-overview.md` §5.7):

```sh
cargo build --release -p optirust
scripts/check-budgets.sh size target/release/optirust     # <= 40 MB
scripts/check-budgets.sh linux target/release/optirust    # runs --smoke under Xvfb + llvmpipe
```

Windows 7 cross build (Docker, only when a change touches windowing, dialogs, file system or dependencies):

```sh
docker build -t optirust-win7 -f docker/win7-cross.Dockerfile docker
docker run --rm -v "$PWD:/src" -w /src -e HOST_UID="$(id -u)" optirust-win7 scripts/build-win7.sh --test optirust
```

It must build both `*-win7-windows-gnu` targets and pass `scripts/check-win7-imports.sh`. Never use `tokio` or any async runtime (`deny.toml` bans them).

Disk: parallel builds inflate `target/debug`. Run `df -h /` before a wave; below 20 GB free delete `target/debug/incremental`. Never delete `target/*-win7-*` or the `optirust-cargo-cache` Docker volume mid-build.

## Crate map

Dependency direction, one way: `optirust-core <- optirust-io <- optirust-ui <- {optirust-pds, optirust-grading, optirust-nest, optirust-cutplan} <- optirust`; `optirust-cutplan` also uses `optirust-nest`.

| Crate | Owns | Entry points |
|---|---|---|
| `optirust-core` | Model, geometry, grading derivation, undo, units, validation. No UI, no I/O. | `crates/optirust-core/src/lib.rs`, `model/`, `geom/`, `grading.rs`, `history.rs`, `validate.rs`, `units.rs`, `marker.rs`, `cutplan.rs` |
| `optirust-io` | `.optx/.optm/.optc`, DXF, RUL, HPGL/2, PDF, CSV | `crates/optirust-io/src/lib.rs`, `dxf/`, `native/`, `plot/`, `rul.rs`, `report.rs` |
| `optirust-ui` | Shell: docking, canvas, palette, shortcuts, themes, i18n, jobs, `--smoke` | `crates/optirust-ui/src/module.rs` (the `Module` trait), `layout.rs`, `shell.rs`, `smoke.rs`, `canvas/`, `widgets/` |
| `optirust-pds` | PDS workspace: tools, ops, panes, menus, plot | `src/actions.rs`, `tools/registry.rs`, `ops/`, `panes/`, `plot/`, `import/` |
| `optirust-grading` | Grading workspace: size table, rules, graded nest, export | `src/export.rs`, `size_table/`, `rule_table.rs`, `nest_view.rs`, `tools/` |
| `optirust-nest` | Marker workspace and the headless nesting engine | `src/engine/` (no egui types), `marker/`, `output/`, `report.rs` |
| `optirust-cutplan` | Order, lay solver, Cut Order, reports | `src/solve.rs`, `apply.rs`, `nesting.rs`, `cut_order.rs`, `report.rs`, `rolls.rs` |
| `optirust` | Binary: `args.rs`, `modules.rs`, `main.rs`; the end-to-end test and the sample | `crates/optirust/tests/e2e_workflow.rs`, `examples/tshirt_sample.rs` |

Other places: `fixtures/` (budget fixtures `style-100.optx`, `marker-1000.optm`), `samples/kaos-lengan-pendek/` (sample outputs), `scripts/`, `packaging/`, `docker/`, `docs/parity-checklist.md` (feature comparison with Optitex 15), `docs/runbooks/win7-smoke.md`.

## Conventions that reviewers check first

- Lengths are `f64` millimetres, X right, Y up, angles in radians counter-clockwise. Display units are never stored. Tolerances are named constants (`EPS_MM` in `crates/optirust-core/src/lib.rs`, `WORKING_TOLERANCE_MM` and friends in `crates/optirust-core/src/geom/mod.rs`).
- Library crates: no `unwrap`, `expect` or `panic!` outside tests; errors are `thiserror` enums. `optirust-core` has no UI or I/O dependency.
- Every public type in `optirust-core` derives `Debug, Clone, PartialEq, serde::Serialize, serde::Deserialize`. Optional fields use `#[serde(default, skip_serializing_if = ...)]`.
- Long work runs on `std::thread` with `std::sync::mpsc`; the UI polls (`crates/optirust-ui/src/jobs.rs`).
- Same input and settings give byte-identical output. The only exception is the UTC stamp in export headers (`optirust_io::utc_now_stamp`).
- Tests pin behaviour and invariants, not incidental formatting. Use `insta` snapshots for DXF/HPGL output (`crates/optirust-io/tests/snapshots/`), `proptest` for geometry invariants, `egui_kittest` for UI (drive by AccessKit label, never pixel position). Long benchmarks are `#[ignore]` and run in release.
- Comments explain why. No TODO or FIXME in committed code.
- New dependency: one-line justification, licence on the `deny.toml` allow-list, prefer crates already in `Cargo.lock`.
- One owner per file per wave. If you need a file you do not own, report `needs-change: <path> - <why>`.
- Never `git commit` or `git push` unless the user asks.

## Recipes

### Add a field to the model

1. Add it to the struct in `crates/optirust-core/src/model/` (or `marker.rs`, `cutplan.rs`) with `#[serde(default, skip_serializing_if = ...)]` so old files still load.
2. Check it in `crates/optirust-core/src/validate.rs`: add an `IssueCode` variant if a new invariant exists.
3. A field that old readers would silently drop needs a format bump: `CURRENT_VERSION` and `MIGRATIONS` in `crates/optirust-io/src/native/migrate.rs`, plus a fixture under `crates/optirust-io/tests/fixtures/native/v1/`.
4. Update `docs/spec/01-core-model.md` and `CHANGELOG.md`. A new domain term goes into `GLOSSARY.md` first.
5. Tests: `crates/optirust-core/tests/` (e.g. `style_json.rs`, `validate_props.rs`) and `crates/optirust-io/tests/native.rs`. The JSON shape is pinned by `crates/optirust-io/tests/snapshots/native__style_json_shape.snap`; review the snapshot diff, never blindly accept.

### Add an undoable edit (command)

Every document mutation goes through `Document::execute` with a `Command<D>` (`crates/optirust-core/src/history.rs`). Most are an `Edit { label, f }` closure. The `label` is a Fluent id of the form `cmd-...` that must exist in the crate's `en` and `id` `.ftl`. In PDS, wrap the closure with `edit(label, |style| ...)` from `crates/optirust-pds/src/ops/mod.rs` and use `with_piece` so protected pieces are refused and snapshots stay shallow (`Arc::make_mut`). A command that would add a validation `Error` returns `CommandError::Invalid`.

### Add a PDS tool or command

1. Write the UI-free edit in `crates/optirust-pds/src/ops/<area>.rs`; unit-test it there.
2. Write the gesture in `crates/optirust-pds/src/tools/<name>.rs`: implement `ToolMachine` (`tools/machine.rs`) and export `pub const ROWS: &[ActionRow]`. `ActionKind` is `Tool`, `Command`, `View` or `Form`; see `tools/notch.rs` for a full tool and `tools/piece_cmds.rs` for plain commands.
3. Register the module in `crates/optirust-pds/src/tools/mod.rs` and add `crate::tools::<name>::ROWS,` on its own line in `rows()` of `crates/optirust-pds/src/tools/registry.rs`.
4. Add the id (`pds-tool-<kebab>`, `pds-cmd-<kebab>`) to `ALL_IDS` in `crates/optirust-pds/src/actions.rs`; give it keys from the default map in `docs/spec/07-ui-shell.md` §6.3 (no new key without checking conflicts).
5. Add the message ids to `crates/optirust-pds/i18n/en/optirust_pds.ftl` **and** `crates/optirust-pds/i18n/id/optirust_pds.ftl`. `crates/optirust-pds/tests/ids_in_catalog.rs` reads every `pds-` literal in `src/` as a message id; a partial prefix literal breaks it.
6. Tests: a behaviour test next to the tool, plus `crates/optirust-pds/tests/registry.rs` stays green.
7. Update `docs/spec/02-pds.md` §5 and `docs/parity-checklist.md`.

### Add a pane or workspace

Pane ids live in `optirust_ui::layout::panes` (`crates/optirust-ui/src/layout.rs`). Add the `PaneId`, put it in the module's default layout (`layout::pds()`, `grading()`, `marker()`, `cutplan()`), draw it from `Module::pane_ui`, title it in `Module::pane_title`, and add a toggle row (`pane_row!` in `crates/optirust-pds/src/panes/mod.rs`). A workspace is a `Module` (`crates/optirust-ui/src/module.rs`) registered in `crates/optirust/src/modules.rs`; panes draw from plain data and return intents, they do not touch the document directly.

### Add a translated string

`fl!` over `i18n-embed`. Each crate with UI has `i18n.toml`, `i18n/en/<crate>.ftl` (source) and `i18n/id/<crate>.ftl`. Ids are `<crate>-<area>-<name>`. Update both files in the same change; parity tests fail otherwise (`parity_problems` in `crates/optirust-ui/src/i18n.rs`). Format numbers with `optirust_core::units`, pass them as string arguments. The i18n loader is process-global: a test that switches language must serialise with a mutex or it flips labels under parallel tests.

### Add a file format or exporter

Put it in `crates/optirust-io/src/`, return `Result<_, IoError>`, report every skipped or approximated entity as an `ImportIssue` (see `optirust-io` skill), write through `write_atomic`, snapshot-test the output, and add an original fixture under `crates/optirust-io/tests/fixtures/`.

## Final checklist

- Gates run and pasted (or "not verified").
- `CHANGELOG.md`, the touched spec or plan, and `GLOSSARY.md` updated.
- `en` and `id` strings both present.
- No Optitex file, string or screenshot used as a source; no GPL code ported (`optirust-clean-room`).
