# Changelog

All notable changes to rajutara-skills. Format: [Keep a Changelog](https://keepachangelog.com/). The version follows the rajutara release the skills were checked against (`skills/index.json`: `version` and `targets.rajutara`).

## [1.5.1] - 2026-11-04

Tracks rajutara 1.5.1: bug fixes, no API change. Checked with `scripts/verify.sh`.

### Changed
- `rajutara-operator`: Stack Along Line is enabled by clicking near an outline in the Grading Work Area (that selects the contour segment); Auto Nest Queue rows start as Regular.

## [1.5.0] - 2026-11-04

Checked against rajutara 1.5.0 with `scripts/verify.sh`.

### Added
- `rajutara-dev`: the test layout (one `tests/all/` binary per crate, a `mod` line per test file, `--test all` filters, snapshot names), faster local builds (`debug = "line-tables-only"`, mold, cargo-nextest), and the Optitex-names rule of `crates/rajutara/tests/all/optitex_names.rs`.
- `rajutara-core-model`: the 1.5.0 fields: Marker `clusters`, `cut_order`, `bump_lines`, `cut_lines`, `flaws`, `texts`; Style `equal_segments`, `fabric`; Piece `placement`, `spread`, `zones`, `from_zone`, `color`, `CutRules` stripe fields; `Vertex::name`; `StackPoint::AlongLine`; the new id types.
- `rajutara-io`: Excel workbooks (`write_xlsx`, `rajutara_io::xlsx`), the import-wizard entry point and `line_mode`.
- `rajutara-nesting`: what the engine respects in a Marker (Fix on Marker, clusters and Fuse Blocks, flaws, Insert to Hole, Cutting Order) and the Auto Nest Queue.
- `rajutara-operator`, wave B: vocabulary (Equal Segments Group, Map Piece and Zone, Track Line, Stripe Group, Spread Pieces, Bump and Cut Line, Flaw), PDS workflows (Segment Editor, Track Lines, Wave Tool, Deform Internals, Equal Segments, Fold Line to Line, Swap Piece Properties, Zones, Fabric And Stripes, Spread and Gather, Save and Restore Placement, Reopen Darts, piece colour, one-line description, Custom seam corner, Theme Settings), Stack Along Line, Marker ply modes, Marker Creation Wizard, Bump/ Cut Lines, Flaws, Internal Text, Substitute Size, Single Piece Gap, the `.xlsx` Report to Excel, and the updated "does not do" list.
- `rajutara-nesting`: bump lines, ply modes, Single Piece Gap, Substitute Size and texts; the report is `write_xlsx_report`.
- `rajutara-operator`: the Optitex names and keys of 1.1.0 to 1.5.0, PDS editing (Notch I in the middle of a segment, Dynamic Input, Global Piece Info, Space move, Point Name), Grading right-click menus and the Grading Notch Tool, Marker clusters, Block Fuse, Insert to Hole, Cutting Order, Auto Nest Queue, and the Cut Plan Create New wizard.
- This changelog.

### Changed
- `rajutara-headless`: the sample's marker report is `kaos-lengan-pendek-marker-report.xlsx` (`write_xlsx_report`).
- Native files are `.rjx`, `.rjm` and `.rjc` everywhere (the old `.optx`, `.optm`, `.optc` are named only as legacy files that still open).
- Test paths follow the merged layout (`crates/<crate>/tests/all/...`); the end-to-end and benchmark commands use `--test all`.
- The model recipe: an optional field keeps format 2; a format bump is only for fields an older build would misread.
- Windows cross-building points to the maintainer's tooling outside the repository.

### Removed
- Paths that no longer exist in rajutara: `docker/`, `docs/plans/`, `docs/runbooks/`, `.omp/skills/`, `scripts/check-win7-imports.sh`, `scripts/nest-memory-i686.sh`.

## [1.0.0] - 2026-11-01

First release: seven skills for rajutara 1.0.0.
