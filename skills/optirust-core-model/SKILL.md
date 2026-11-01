---
name: optirust-core-model
description: "The optirust domain model and its invariants with exact Rust type names - Style, Piece, Contour, Notch, Grainline, SizeTable, GradeRule, Marker, Order, CutPlan, IDs, units, validation. Use when reading, building or changing documents in optirust-core, or when a task needs to know what a field means."
---

# optirust-core-model

Source of truth: `docs/spec/01-core-model.md` (the contract), `GLOSSARY.md` (vocabulary), and the code in `crates/optirust-core/src/`. When this skill and the code disagree, the code and spec win; fix this skill.

`optirust-core` has no UI and no file I/O. Every public type derives `Debug, Clone, PartialEq, Serialize, Deserialize`. `crates/optirust-core/src/lib.rs` re-exports `kurbo::{BezPath, Point, Rect, Vec2}` and everything below at the crate root (`optirust_core::Style`).

## Units and coordinates

- Lengths are `f64` **millimetres**. Areas are mm². Angles are radians, counter-clockwise from +X. X right, Y up (DXF convention). Percentages are plain percent (`2.5` = 2.5 %).
- Never store a display unit. Parse and format only through `optirust_core::units`: `Unit { Mm, Cm, Inch }`, `UnitSystem { Metric, Imperial }`, `NumberFormat`, `parse_length(text, unit)` (accepts `12.5`, `12,5`, `1 3/8`, suffixes; rejects |value| > 100 m, `MAX_LENGTH_MM`), `format_length`, `format_fabric_length` (`12 m 35 cm`).
- Tolerances are named constants: `EPS_MM = 0.001` (same point), `geom::WORKING_TOLERANCE_MM = 0.2`, `geom::FLATTEN_TOLERANCE_MM = 0.02`, `geom::MITER_LIMIT = 4.0`.

## Style and Piece (`model/style.rs`)

```text
Style { name, author, notes, size_table: Arc<SizeTable>, rule_table: Arc<RuleTable>,
        pieces: Vec<Arc<Piece>>, default_material, desk: Desk, ids: IdAlloc }
Piece { id: PieceId, name, code, description, quantity: u16, pair: bool, material,
        protected, on_desk, line: LineKind, contour: Contour, mirror: Option<MirrorLine>,
        grainline: Grainline, internals, notches, drill_holes, annotations, darts, pleats,
        label: PieceLabel, grading: BTreeMap<PointId, GradeRule>, stack: StackPoint, cut: CutRules }
```

- A Style is the unit a `.optx` saves. `Style::new(name)` has one size `M` as Base Size, no pieces, default material `Main`.
- A Piece stores geometry for the **Base Size only**. Other sizes are derived (see Grading). ADR-0004.
- `pieces` order is the Pieces Window, Plot and export order. `Arc<Piece>` makes undo snapshots shallow; mutate with `Style::piece_mut(id)` (copy-on-write, refuses `protected` pieces with `CommandError::Protected`). `piece_mut_even_if_protected` exists only for the protect toggle and for Size Table commands.
- `quantity >= 1`; `pair` means each copy is also cut mirrored (left/right).
- `line: LineKind { Sew, Cut }` says which line `contour` stores; the other is derived: `Piece::sewing_line()`, `Piece::cutting_line()` return `DerivedLine`.
- `Piece::new(&mut ids, name, contour)` allocates the piece id and a default grainline. `with_fresh_ids` / `remap_ids` renumber a piece (paste, merge) via `IdMap`.
- `CutRules { rotation: RotationRule { OneWay, TwoWay, FourWay, EightWay, Any }, flip: FlipRule { None, X, Y, Both }, tilt, buffer, fold }` drives Marker orientations.

## Contour and points (`model/contour.rs`)

- `Contour { points: Vec<Vertex>, shapes: Vec<SegmentShape> }` is a closed loop; `shapes.len() == points.len()` (`shapes[i]` joins point i to i+1, wrapping). `SegmentShape { FromPoints, Arc { bulge } }`.
- `Vertex { id: PointId, at: Point, kind: PointKind, seam: Option<SeamAllowance>, corner: SeamCorner, connected: Option<PointId> }`. `PointKind { Turn, Curve }`: two Turn Points with no Curve Point between them are joined by a straight line; consecutive Curve Points shape one curve.
- `SeamAllowance { width, end_width }` (mm, >= 0). `SeamCorner { Intersect, Bevel{distance}, Square{side}, .. }`. The seam lies outside the contour for `LineKind::Sew`, inside for `Cut`.
- `InternalLine { id, points, shapes, closed, kind: InternalKind { Draw, Cut, Sew, Fold, Stripe, Plaid }, symmetric }`. An internal vertex's `connected` names the contour point whose graded position it follows.
- Evaluation helpers live in `geom/` (`contour.rs`, `curve.rs`, `seam.rs`, `unfold.rs`, `notch.rs`, `transform.rs`): `transform_piece`, `unfold_half`, `notch_marks`, `cutting_area`.

## Features (`model/features.rs`)

`Notch { id, shape: NotchShape { V, T, I, L, U, Box }, depth, width, reverse, at: NotchAt, direction, symmetric, output: ToolCommand }`; defaults `DEFAULT_NOTCH_DEPTH_MM = 7.0`, `DEFAULT_NOTCH_WIDTH_MM = 5.0`. `NotchAt::Point(PointId)` or `Between { prev, next, place: NotchPlace { relation: NotchRelation { Proportional, FromPrevious, FromNext }, value, per_size } }`. `Grainline { start: PiecePoint, end: PiecePoint, initial_angle }` (direction is `end - start`, must not be zero length). Also `MirrorLine`, `DrillHole`, `Annotation`, `Dart`, `Pleat`, `PieceLabel`.

## Sizes and grading (`model/sizes.rs`, `grading.rs`)

- `SizeTable { sizes: Vec<Size>, base: usize }`. Size names: non-empty, unique, no whitespace (ASTM SIZE LIST is whitespace separated). Sizes are **positional**: deltas align with `sizes` by index; Markers and Orders refer to sizes by name. `SizeTable::index_of(name)`.
- `GradeRule { deltas: Vec<Vec2> }`: cumulative X/Y displacement from the Base Size for every size; `deltas[base]` is always zero; `deltas.len() == sizes.len()`. `GradeRule::zero(n)`.
- `Piece::grading: BTreeMap<PointId, GradeRule>` holds the Grade Points. Contour points without a rule move in proportion (by arc length) between neighbouring Grade Points; none on the contour means zero.
- `RuleTable { name, rules: Vec<NumberedRule { number: i32, name, rule }> }`: numbered rules, copied onto points (no live link), exchanged as RUL.
- `StackPoint { None, Point{point, axes: StackAxes}, Grainline }` is display-only alignment of the Graded Nest. It never changes geometry.
- `optirust_core::grading::piece_for_size(&piece, &sizes, size_index) -> Piece` (Base Size returns a clone), `graded_nest(&piece, &sizes) -> Vec<Piece>`, `incremental(&rule, &sizes)`. A derived piece has empty `grading` and notch values already resolved for that size.
- Moving a piece leaves deltas unchanged; rotating by theta rotates every delta; flipping negates dX or dY. `transform_piece` does all of it; never move points by hand.

## Identifiers (`ids.rs`)

Newtypes over `u64` with `#[serde(transparent)]`: `PieceId, PointId, NotchId, InternalLineId, DrillHoleId, AnnotationId, DartId, PleatId, StyleRefId, RequestId, InstanceId, PlannedMarkerId, LayId, FabricRollId`. One `IdAlloc` per document (`Style::ids`, `Marker::ids`, `CutPlan::ids`) serves every type; ids are never reused after deletion. `ids.next::<PointId>()`. Every id in a valid document is below `ids.next_free()`. A tool that deletes a point and creates another gives the new one a new id; moving keeps the id (stable identity for future 3D stitches, ADR-0005).

## Marker and Cut Plan data

```text
Marker { name, material: Material, max_length, plies, margins: Margins, buffer,
         styles: Vec<EmbeddedStyle>, requests: Vec<SizeRequest>, pieces: Vec<MarkerPiece>, ids }
Material { name, width, ply_mode: PlyMode { Single, Tubular, Faced, Folded },
           shrink_length_pct, shrink_width_pct, cost_per_m, weight_gsm }
EmbeddedStyle { id: StyleRefId, source: Option<String>, source_crc32, style: Arc<Style> }
SizeRequest { id, style, size: String, bundles, direction: BundleDirection { OneWay, Opposite, Any } }
MarkerPiece { id: InstanceId, request, bundle, piece, copy, mirrored, pose: Option<Pose> }
Pose { at: Point, rotation, flip: Flip }        // pose None = waiting in the Piece Bar
Order { name, client, operator, lines: Vec<OrderLine { colour, quantities }> }
CutPlan { name, style: EmbeddedStyle, order, material, limits: LayLimits, costs: CostInputs,
          markers: Vec<PlannedMarker>, lays: Vec<Lay>, rolls: Vec<FabricRoll>, ids }
```

- X runs along the marker length (the warp), Y across the width. A Marker is made on one Material; its pieces are instances (`MarkerPiece`) derived from `requests`, one per (Bundle, piece, copy, pair side). Instances are rebuilt by `optirust_nest::marker::instances::sync_instances`; never push to `Marker::pieces` by hand.
- `Order::lines[i].quantities` and `PlannedMarker::ratio` are positional over the embedded Style's Size Table.
- `Lay { id, marker: PlannedMarkerId, colour, plies }`. `FabricRoll { id, code, colour, shade, width, length }`: roll `code` trimmed, non-empty, unique.
- A Marker embeds a copy of each Style (`EmbeddedStyle`); `source_crc32` detects that the source `.optx` changed (`optirust_io::style_crc32`).

## Commands and history (`history.rs`)

`Command<D>` has `label() -> &'static str` (a Fluent id `cmd-...`) and `apply(self, &mut D) -> Result<(), CommandError>`. `Edit { label, f }` is the closure form. `Document<D> { content, history, path }` with `execute`, `undo`, `redo`, `is_dirty`, `mark_saved`; `History<D>::new(limit)` with `DEFAULT_UNDO_DEPTH` (100, 50 on 32-bit). `CommandError { Protected(PieceId), Missing, Invalid(Vec<Issue>) }`. `reject_new_errors(before, after)` turns newly introduced validation errors into `Invalid`. Opening, saving, zoom, pan and selection are not undoable.

## Validation (`validate.rs`)

`validate_style`, `validate_piece(piece, sizes)`, `validate_marker`, `validate_cut_plan` return `Vec<Issue { severity: Severity { Error, Warning }, piece: Option<PieceId>, code: IssueCode }>`. Loading a document refuses it on any `Error` (`IoError::Invalid`) and returns the warnings. Codes to know:

| Code | Severity | Meaning |
|---|---|---|
| `TooFewPoints`, `ShapeCountMismatch`, `ZeroGrainline`, `MirrorLineNotStraight` | Error | structural |
| `SelfIntersection{size}` | Error at Base Size, Warning at graded sizes | contour crosses itself |
| `GradeRuleLength(PointId)` | Error | `deltas.len() != sizes` or base delta not zero |
| `BadSizeName`, `BadBaseSize`, `NegativeSeamWidth` | Error | tables |
| `DanglingReference(u64)`, `DuplicateId(u64)` | Error | ids |
| `CountMismatch(list)`, `InvalidNumber(field)`, `PlyLimits`, `PercentOutOfRange`, `UnknownSize`, `WiderThanMaterial` | Error | Marker and Cut Plan |
| `DuplicatePieceName`, `NameTooLongForAstm` (> 20 chars), `CoincidentPoints`, `BadRollCode` | Warning | |

Caps against hostile files: `MAX_CONTOUR_POINTS = 20_000`, `MAX_BUNDLES = 9999`, `MAX_MARKER_INSTANCES = 100_000`.

## Building a Style in code

Read `crates/optirust/examples/tshirt_sample.rs` (functions `piece`, `grade`, `notch`, `tee_style`): a Contour is `Vertex::new(ids.next(), Point::new(x, y), PointKind::Turn)` per point plus `SegmentShape::FromPoints` per segment, wrapped by `Piece::new(&mut style.ids, name, contour)`. Then set `size_table`, numbered rules and `piece.grading.insert(point_id, rule)`. Always run `validate_style` and refuse on errors before saving. Test helpers: `crates/optirust-core/src/testing.rs` (`rect_piece`, `style_with_pieces`, `rich_style`; `#[doc(hidden)]`, for tests only).

## Rules when extending

New domain term -> `GLOSSARY.md` first. New field -> `serde(default)`, a validation rule, spec update, and a format bump if old readers would drop it (`crates/optirust-io/src/native/migrate.rs`). Do not add a display unit, a UI type or a file path to `optirust-core`.
