---
name: optirust-nesting
description: "Use and tune the optirust auto-nesting engine (no-fit polygons, bottom-left fill, annealing) - Stop modes, seeds, determinism, threads, reading metrics and conflict reports, the 300-piece 60 s gate and the ESICUP benchmarks. Use when nesting a Marker from code, debugging marker efficiency or overlaps, or changing crates/optirust-nest/src/engine."
---

# optirust-nesting

Crate `optirust-nest`. The engine (`crates/optirust-nest/src/engine/`) has no egui types in its API and is also called by Cut Plan. Spec: `docs/spec/04-marker.md` §6 (engine), §8 (metrics); contract: `docs/spec/01-core-model.md` §15.2. The algorithm is original, built from published papers (ADR-0002); never port code from a GPL nester.

## Two entry levels

**1. Marker level** (almost always what you want): `optirust_nest::{nest_marker, NestMarkerOptions, NestedMarker, NestError, marker_for_ratio}` (`crates/optirust-nest/src/marker/glue.rs`).

```rust
use std::time::Duration;
use optirust_nest::{nest_marker, NestMarkerOptions};
use optirust_nest::engine::{Control, Stop};

let opts = NestMarkerOptions { stop: Stop::Time(Duration::from_secs(60)), seed: 1, ..Default::default() };
let nested = nest_marker(&marker, &opts, &|_progress| Control::Continue)?;   // NestedMarker
// nested.marker (poses applied), nested.length (mm), nested.efficiency_pct, nested.unplaced
doc.execute(optirust_nest::marker::commands::apply_nest(
    nested.marker.pieces.iter().map(|p| (p.id, p.pose)).collect()))?;       // one undoable command
```

`NestMarkerOptions::default()`: `Stop::Time(20 s)`, `target_efficiency: None`, `seed: 1`, `threads: 0`, `unlimited_length: true`, `keep_placed: true`. `nest_marker` does not mutate `marker`; apply the poses yourself. Errors: `NestError::NothingToNest` (every request has 0 Bundles, or nothing waits in the Piece Bar), `NestError::Panicked(msg)` (engine panic caught, Marker untouched, ADR-0009).

Build a Marker first: `MarkerSetup::new(name, buffer_mm)` (`crates/optirust-nest/src/marker/props.rs`; set `width`, `material`; `into_marker()` validates), then `add_style(embedded)`, `set_setup(setup)`, `set_request(style_id, size_name, bundles, BundleDirection)` from `optirust_nest::marker::commands`. For a Cut Plan ratio: `marker_for_ratio(&embedded_style, &material, max_length, &ratio, name)` (One Way bundles per size, no margins, no buffer). See `crates/optirust/examples/tshirt_sample.rs` `marker_of` and `main`.

**2. Engine level**: `optirust_nest::engine::{nest, place_in_order, NestItem, Orientation, NestSettings, Stop, Progress, Control, NestResult, Placed}` (`engine/api.rs`, `engine/driver.rs`). `nest(&items, &fixed, &settings, &progress) -> NestResult { placed, unplaced, length, efficiency }`. Use it for benchmarks and pure-geometry tests; example: `crates/optirust-nest/tests/nest_env_independent.rs`.

## Settings that matter

| Setting | Meaning | Notes |
|---|---|---|
| `Stop::Time(d)` | wall-clock limit counted from the start, shape preparation included | search stops at 90 %, compaction at 97 %; result depends on machine speed. Operators get 60 s by default in the dialog (`docs/spec/04-marker.md` §6.5). |
| `Stop::Iterations(n)` | fixed improvement iterations | fully deterministic; use in tests and CI. The four logical workers are fixed, so the thread count does not change the result. |
| `seed` | seed of every random choice | same seed + `Stop::Iterations` = same poses, whatever the environment (`nest_env_independent.rs`). Worker `w` uses `seed ^ w`. |
| `target_efficiency` | stop early at this percent | Optitex "Efficiency Limit". |
| `threads` | 0 = available parallelism | capped at `MAX_THREADS` (4; 2 on 32-bit). `effective_threads(n)` gives the result. |
| `cache_limit` | byte cap of the no-fit-polygon LRU | `DEFAULT_CACHE_LIMIT` = 256 MB (128 MB on 32-bit). Raise only with RAM to spare; the i686 budget is 1 GB peak for 300 pieces. |
| `strip_width` | Material width minus bottom and top margins | filled for you by `nest_marker`. |
| `max_length` | `f64::INFINITY` = unlimited length | `nest_marker` sets it from `unlimited_length` and `Marker::max_length`. |
| `keep_placed` | placed instances stay as fixed obstacles; only the waiting ones are nested around them | off: every instance is nested afresh and existing poses are replaced. |

What shapes the result besides the engine: `Marker::buffer` and `CutRules::buffer` (each ring is grown by half the Marker buffer plus the piece buffer), the Material shrinkage (`shrink_length_pct`, `shrink_width_pct`), and each piece's `RotationRule`/`FlipRule` (orientation sets: OneWay {0}, TwoWay {0, pi}, FourWay and EightWay at multiples of pi/2 and pi/4, Any = multiples of pi/4). More allowed orientations raise efficiency and cost time. Bundle direction `OneWay` ties a bundle to one 180-degree state; `Opposite` fixes it per bundle.

Tuning order: raise time (or iterations) before touching anything else; then allow more orientations on pieces where grain permits; then reduce buffer only if the Operator accepts it. Compare runs by fixing `seed` and `Stop::Iterations`; compare time-limited runs only on the same machine.

## Progress and cancel

`progress: &(dyn Fn(Progress) -> Control + Sync)` is called about every 50 ms with `Progress { elapsed, best_length, best_efficiency }` (both 0 until the first full pass ends). Return `Control::Cancel` to get the best packing so far. Run it off the UI thread (`std::thread`, `mpsc`); the app does this through `optirust-ui` jobs.

## Reading the result

```rust
use optirust_nest::marker::{instances::ShapeBook, metrics::{metrics, conflicts}};
let mut book = ShapeBook::default();
let m = metrics(&marker, &mut book);        // Metrics { placed, requested, bundles_placed, used_length, efficiency_pct,
                                            //   waste_area, cutting_length, per_garment, fabric_for_lay, fabric_cost, .. }
let c = conflicts(&marker, &mut book);      // c.overlap_count(), c.outside, c.in_margin (sets of InstanceId)
```

- **Efficiency** = placed cutting-line area (after shrinkage, unbuffered) / (Material width x used length) x 100. **Used length** = largest X of any placed cutting line plus the right margin. **Per garment** = used length / complete bundles.
- A good run has `unplaced == 0`, `overlap_count() == 0`, `in_margin` empty. Overlaps are allowed by hand placement (hatched red) but never come out of the engine: every result is verified by an exact `i_overlay` check (intersection area under 0.01 mm², `crates/optirust-nest/src/engine/verify.rs`). A piece wider than the Material width stays unplaced; `validate_marker` flags it as `WiderThanMaterial`.
- Reports: `report_data(&marker, &mut book, &ReportMeta{..}, &tr)` then `write_csv_report(&data, path)` or `report_doc` + `optirust_io::write_report_pdf` (`crates/optirust-nest/src/report.rs`). Sections: General, Order, Pieces, Notches.
- Output: `marker_job` + `plot_marker(&job, &PlotTarget::Pdf(PdfPage::A0) | PlotTarget::Hpgl(setup), path)`; cut file: `optirust_nest::output::cutfile::{cut_job, write_cutfile}` (generic HPGL/2; default pen 2 knife, pen 3 drill).

## Gates and benchmarks

- **300-piece gate** (D10): auto-nest 300 pieces in at most 60 s, 0 unplaced, 0 overlaps, efficiency above 70 % asserted (README reports 90.1 % in 58 s on the release benchmark). Release profile only:

```sh
cargo test -p optirust --release --test e2e_workflow phase_1b_300_piece_marker_nests_within_60_s_and_plots -- --include-ignored --nocapture
```

  In debug it is `#[ignore]`d because the engine is only fast enough optimised.
- **ESICUP garment benchmarks** (not committed, no stated licence): `scripts/fetch-esicup.sh`, then

```sh
OPTIRUST_ESICUP_DIR=target/esicup cargo test -p optirust-nest --lib --release -- --ignored esicup
```

  Required at `Stop::Time(60 s)`, 4 threads: SHIRTS >= 84.0 %, TROUSERS >= 87.0 %, SWIM >= 67.0 %, ALBANO >= 84.0 %, SHIRTS x 3 (297 pieces) >= 83.0 % with no overlaps; plus an 8-seed sweep at `Stop::Iterations(400)` in 83-87 % with zero repairs (`crates/optirust-nest/src/engine/esicup_tests.rs`).
- i686 memory: `scripts/nest-memory-i686.sh` runs the SHIRTS x 3 benchmark (297 pieces) under Wine inside `docker/win7-cross.Dockerfile`; peak RSS must stay under 1 GB.
- Always run `cargo test -p optirust-nest` (debug is fine for everything except the gates above) and `cargo clippy -p optirust-nest --all-targets -- -D warnings`.

## Changing the engine

1. Keep the API in `engine/api.rs` free of egui and I/O. Do not add an async runtime; use `std::thread`.
2. Determinism is a feature: never read the environment, the clock (other than the `Stop::Time` budget) or hash-map iteration order into a decision. Keep `nest_env_independent.rs` green.
3. A packing the search returns must be overlap-free by construction; `verify_and_repair` is the safety net, and the sweep asserts it is never needed. Do not widen `OVERLAP_AREA_TOL_MM2` to hide a defect.
4. Re-run the ESICUP gates in release before and after; report the efficiencies and wall times, not just pass/fail.
5. Update `docs/spec/04-marker.md` §6 and `CHANGELOG.md`.

## Cut Plan integration

`optirust_cutplan::nesting::{EngineNester, nest_plan, NestStop, save_markers}`: marker `i` of a plan is nested with seed `NEST_SEED_BASE + i` (`NEST_SEED_BASE = 1`), so re-running the same plan repeats. `NestStop::Seconds(n)` is per marker (Preferences default 20 s, `crates/optirust-cutplan/src/ui/workspace.rs`), `NestStop::Iterations(n)` is for tests. If a nested marker is longer than the table, `nest_plan` solves once more with the real lengths.
