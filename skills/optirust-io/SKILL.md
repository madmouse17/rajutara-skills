---
name: optirust-io
description: "Import and export recipes for optirust files - ASTM D6673 / AAMA-292 DXF, ASTM RUL grade rules, HPGL/2, PDF plots and reports, CSV, and the native .optx/.optm/.optc containers - with ImportIssue handling and test fixtures. Use when reading or writing any file format in optirust-io, or scripting conversions."
---

# optirust-io

Crate `optirust-io` (`crates/optirust-io/src/lib.rs`) owns every file format; it depends only on `optirust-core`. Specs: `docs/spec/02-pds.md` §7 (DXF), §8 (dialogs), §9 (plot), `docs/spec/03-grading.md` §7 (RUL), `docs/spec/01-core-model.md` §9 (native container). Optitex's own formats (`.pds`, `.mrk`, `.dsn`, `.ord`, its rule tables) are never read or written (ADR-0001); RUL is the open exception (ADR-0013). See `optirust-clean-room`.

| Format | Direction | Entry points (`optirust_io::`) |
|---|---|---|
| `.optx` Style, `.optm` Marker, `.optc` Cut Plan (zip with `manifest.json` + `document.json`, format 2) | open, save | `load_style`, `save_style`, `load_marker`, `save_marker`, `load_cut_plan`, `save_cut_plan`, `embed_style`, `style_crc32` |
| ASTM D6673 / AAMA-292 DXF | import, export | `import_dxf`, `import_dxf_cancellable`, `parse_dxf`, `export_dxf`, `render_dxf` |
| ASTM RUL | import, export | `read_rul`, `write_rul`, `write_rul_atomic` (import happens automatically beside a DXF) |
| HPGL/2 | export | `render_hpgl`, `plot_hpgl` with `PlotJob` + `PlotterSetup` |
| PDF (A4 tiled, A0, A4 fit) | export | `render_pdf`, `plot_pdf` with `PlotJob` + `PdfPage`; reports: `render_report_pdf`, `write_report_pdf` with `ReportDoc` |
| CSV | import, export | `read_csv_rows`, `write_csv` |

All writers go through `write_atomic(path, bytes, keep_backup)` (`crates/optirust-io/src/fsutil.rs`): temp file then rename, a crash leaves the old file. `save_*` keeps the previous file as `<file>.bak`.

## The ImportIssue contract

Importers and exporters never drop or change data silently. Everything skipped, approximated, defaulted or changed becomes `ImportIssue { severity: Severity, location: String, message: String }` (`crates/optirust-io/src/error.rs`; build with `ImportIssue::warning(loc, msg)` / `ImportIssue::error(loc, msg)`). `Error` = data was lost or an item was unusable; `Warning` = approximated or defaulted. Locations read like `block FRONT, layer 81`.

Rules for any code you write or call:

1. A function that can lose information returns `(T, Vec<ImportIssue>)` or `Result<(T, Vec<ImportIssue>), IoError>`. Never `log::warn!` and move on.
2. The caller must show the list. In the app, PDS shows it in the Import Report pane (`crates/optirust-pds/src/panes/import_report.rs`); in a script, print it and decide: treat any `Severity::Error` entry as a failed conversion unless the user accepted the loss.
3. An import opens whenever at least one piece was built. Do not turn warnings into failures by default.
4. `IoError` variants: `Io{path,source}`, `Format`, `NewerVersion{found,supported}`, `Invalid(Vec<Issue>)` (core validation errors, file refused), `Dxf`, `Refused`, `Cancelled`. Map them to words for the user; never `unwrap`.

## Import a DXF (graded or flat)

```rust
use optirust_io::{import_dxf, DxfImportOptions, DxfFlavor};
let opts = DxfImportOptions { flavor: DxfFlavor::Auto, ..DxfImportOptions::default() };
let (style, issues) = import_dxf(path, &opts)?;      // reads the sibling .rul by itself
```

- `Auto` picks ASTM if layers 80-87 or system text exist, else AAMA if numbered layers 1-15 exist, else plain DXF. Units come from `Units:` text, then `$INSUNITS`, then cm; `opts.units = Some(..)` forces a unit and wins (a conflict is reported).
- Defaults (dialog defaults): tolerance 0.5 mm, curve angle 3 degrees, notch 7 x 5 mm, `max_drill_radius` 3 mm, `build_sizes: true` (graded-nest blocks become one piece with all sizes; `false` keeps each block its own piece). Other switches: `ignore_text`, `contour_only`, `scale`, `drill_diameter`, `curve_tolerance`.
- The grade rules come from the `.rul` named by `Grade Rule Table:` in the DXF, same folder, case-insensitive; the name must be a plain file name (no `/`, `\`, `..`). A missing RUL gives a Style with no Grade Rules and an issue.
- Limits: a file over 64 MiB (`MAX_DXF_BYTES` in `crates/optirust-io/src/dxf/scan.rs`) or binary DXF is refused with `IoError::Dxf`; no piece found is also `IoError::Dxf`.
- Background job: `import_dxf_cancellable(path, &opts, &|| cancelled.load(..))` returns `IoError::Cancelled`.
- In-memory: `parse_dxf(bytes, Some(rul_text), &opts)`; the Style is named `Imported` when the file has no `Style Name:`.
- After import, run `optirust_core::validate_style(&style)` and read `docs/spec/02-pds.md` §7.4 for the algorithm.

## Export a DXF (+ RUL)

```rust
use optirust_io::{export_dxf, DxfExportOptions, GradingExport, utc_now_stamp};
let opts = DxfExportOptions { grading: GradingExport::RuleFile, created: utc_now_stamp(), ..Default::default() };
let issues = export_dxf(&style, Path::new("out/shirt.dxf"), &opts)?;   // also writes out/shirt.rul
```

- `flavor` must be `Astm` (R13, layers 1-15 and 80-87) or `Aama` (R12, layers 1-15; notch shapes other than V/I are written as V/I with a warning). `Auto` and `Plain` are refused with `IoError::Refused`.
- `GradingExport`: `RuleFile` (default: Base Size blocks with `# n` markers plus the `.rul`), `GradedNest` (one block per size, no rule file), `BaseSizeOnly`.
- Other options: `metric` (mm, 2 decimals; else inch, 4), `boundary: BoundaryLine { CutWithSewLine, SewLineOnly }`, `visible_sizes_only`, `positive_rule_numbers`, `keep_symmetry` (halves stay halves), `pieces: Option<Vec<PieceId>>`, `chord_tolerance` (0.05 mm), `notch_rules`.
- `created` is the `("dd-mm-yyyy", "hh:mm")` header stamp. Default is the epoch so tests are byte-stable; real exports pass `utc_now_stamp()`.
- Both files are staged before either replaces its predecessor. The DXF file name must not end in `.rul`. Non-ASCII file stems get a warning because the `Grade Rule Table:` text is ASCII.
- Prefer `optirust_grading::export::run_export(&style, &ExportRequest{..}, created)`: it first refuses invalid grading data (`ExportError::Blocked(Vec<GradingIssue>)`). `run_rul_export` writes the Rule Table alone.
- `render_dxf(&style, &opts) -> DxfExport { dxf: Vec<u8>, rul: Option<String>, issues }` returns bytes without touching disk.

## RUL

`read_rul(text) -> (RuleTable, size_names, sample_size, issues)`: rule values are mm, cumulative from the sample size. A rule with the wrong number of pairs is an error for that rule only. A file without `SIZE LIST` or with a repeated size name is `IoError::Format`. `write_rul(&table, &sizes, &RulOptions{metric, positive_rule_numbers, created})`. Fixture: `crates/optirust-io/tests/fixtures/dxf/graded3.rul`. Deviations from real-world RUL files are reported as `ImportIssue`, never guessed (ADR-0013).

## Plot: HPGL/2 and PDF

The module (PDS or Marker) builds a `PlotJob { sheet: Rect, items: Vec<PlotItem { kind: PlotKind, path: BezPath, text }> }` in sheet millimetres; the writers only draw it.

- PDS pieces: `optirust_pds::plot::job::plot_job(&style, &Selection::default(), &values)`; Marker: `optirust_nest::output::plot::{marker_job, header_lines, plot_marker, PlotTarget}`; cut file: `optirust_nest::output::cutfile::{cut_job, write_cutfile}`.
- `plot_pdf(&job, PdfPage::A4Tiled | A0 | A4Fit, path)`: A4Tiled is 210 x 297 mm pages with 10 mm margins and an assembly map; A0 is one page when the sheet fits; A4Fit scales the whole sheet onto one page (not 1:1). More than 10 000 tiles is refused.
- `plot_hpgl(&job, &PlotterSetup, path)`: set `paper_width` to the roll width; `rotate_90: true` for pieces, `false` for markers. A plot wider than the paper is refused (`IoError::Refused`: no strip clipping yet). Check width first with `optirust_nest::output::plot::check_job`.
- PDF text is Helvetica/WinAnsi: other characters become `?` with a warning. No creation date, so same job gives same bytes.
- Reports: build `ReportDoc { title, sections: Vec<ReportSection { heading, facts, table, drawing }> }` and call `write_report_pdf`; numbers arrive as already formatted strings.

## CSV

`write_csv(&rows, path)`: UTF-8, no BOM, LF, `.` decimal. Cells that start with `=`, `@`, tab, CR, or `+`/`-` not followed by a number get a leading `'` (formula injection from foreign piece names). `read_csv_rows(text)` strips one BOM, no header handling; callers (`optirust_cutplan::order::import_order_csv`, `optirust_cutplan::rolls::import_rolls_csv`) skip bad rows with an issue each.

## Native documents

`load_style(path) -> (Style, Vec<Issue>)` validates: any `Error` refuses the file (`IoError::Invalid`), warnings ride along. A file saved by a newer build is `IoError::NewerVersion`. Older versions migrate step by step (`crates/optirust-io/src/native/migrate.rs`, `CURRENT_VERSION = 2`). Documents are zip files holding `manifest.json` (`{"format":"optirust-style","version":2,"generator":"optirust 1.0.0"}`) and `document.json`, so a script can read them with any zip and JSON library (`unzip -p samples/kaos-lengan-pendek/kaos-lengan-pendek.optx document.json`). `save_*` refuses a document it could not read back (NaN, over `MAX_DOCUMENT_BYTES` = 256 MiB). `embed_style(path, id)` loads a `.optx` for a Marker or Cut Plan with its CRC-32. Autosave: `autosave_path`, `newer_autosave` (`<stem>.autosave.<ext>`, no `.bak`).

## Fixtures and tests

- Original fixtures only (ADR-0001): `crates/optirust-io/tests/fixtures/dxf/astm_minimum.dxf`, `crates/optirust-io/tests/fixtures/dxf/graded3.rul`, `crates/optirust-io/tests/fixtures/native/v1/`; large ones: `fixtures/style-100.optx`, `fixtures/marker-1000.optm` (regenerate with `cargo run -p optirust-io --example budget_fixtures`).
- Build DXF text in tests with `crates/optirust-io/tests/common/dxf_builder.rs` (`Dxf::new().block(name, body().rect_piece(..)).text()`), not by pasting vendor files.
- Snapshot outputs with `insta` (`crates/optirust-io/tests/snapshots/`); round-trip with `proptest` (`crates/optirust-io/tests/dxf_roundtrip.rs`). Run `cargo test -p optirust-io`.
- Never commit a DXF or RUL that came from a commercial CAD product's sample pack.
