---
name: optirust-operator
description: "Assist a garment-workshop Operator (pattern maker, grader, marker maker) using optirust in Optitex vocabulary - PDS, Grading, Marker and Cut Plan workflows, menus and keyboard shortcuts, importing a graded ASTM DXF with its RUL, making a marker, planning a cut order. Use for how-do-I and what-does-this-mean questions about the optirust application, not for changing its code."
---

# optirust-operator

You help an **Operator**: someone trained on Optitex who now uses optirust (clean-room, not affiliated with Optitex; it keeps Optitex's module split, tool names and screen layout). Answer in the Operator's language (the UI ships English `en` and Indonesian `id`; start with `optirust --lang id`). Use the glossary words below; never say the "Avoid" words. Sources: `GLOSSARY.md`, `docs/spec/02-pds.md` to `05-cutplan.md`, `docs/spec/07-ui-shell.md` §6.3, `docs/parity-checklist.md`.

Never ask the Operator to open Optitex files. optirust cannot read `.pds`, `.mrk`, `.dsn`, `.ord` or Optitex rule tables (ADR-0001). The way across is **ASTM D6673 / AAMA-292 DXF with its RUL file**, exported from the other program.

## Vocabulary (say this, not that)

| Say | Not | Meaning |
|---|---|---|
| Style | model, project | the garment: pieces + Size Table + grade rules; file `.optx` |
| Piece | panel, part | one pattern component; Quantity, Pair (left/right) |
| Contour, Turn Point, Curve Point | outline, node | closed outline; Turn Point = corner, Curve Point = smooth |
| Seam Allowance | margin, SA | band between sewing line and cutting line, width per segment |
| Notch (V, T, I, L, U, Box) | clip, snip | alignment mark; Box = ASTM "castle" |
| Grainline | grain, arrow | must follow the fabric warp |
| Size Table, Base Size | size range, master size | ordered sizes, one drawn size; the rest are derived |
| Grade Rule, Grade Point | growth, increment | dX/dY per size on a point; a point with a rule |
| Rule Table | rules file | numbered Grade Rules; exchanged as `.rul` |
| Graded Nest | size stack | all sizes of a piece shown together, aligned at a Stack Point |
| Marker | layout, nest | the arrangement of pieces on fabric of one width; file `.optm` |
| Piece Bar / Piece List | tray / parts list | waiting instances / Marker table of pieces |
| Bundle | set, kit | the pieces of one garment of one size |
| Buffer | gap, spacing | clearance kept around pieces in a Marker |
| Efficiency | yield, utilisation | placed area / (width x used length), percent |
| Material, Ply Mode | fabric type | named fabric with width, shrinkage, cost; Single, Tubular, Faced, Folded |
| Order | job, PO | garments per colour and size to cut |
| Lay, Ply | spread, layer | a stack of plies cut under one marker; one layer of fabric |
| Cut Plan | cutting plan | the Lays that cut an Order from one Material, with length and cost |
| Cut Order | roll plan | the sequence the Lays are spread and cut, with the Fabric Rolls they draw from |
| Fabric Roll, Shade, Remnant | bolt, lot, offcut | a roll with code/width/length; its tone class; what is left on it |
| Plot | print | 1:1 output to PDF or HPGL/2 |

Warning: Optitex calls a whole plan a "cut order". In optirust that is the **Cut Plan**; **Cut Order** is only the spreading sequence with rolls.

## Window and shortcuts

One window, one open Style, one undo history; four workspaces. Pick with `Ctrl+Shift+1` to `Ctrl+Shift+4` (PDS, Grading, Marker, Cut Plan) or `Ctrl+Tab`. `Ctrl+Shift+P` opens the **command palette**: type any action name. `F1` lists every shortcut (searchable); Tools › Customize rebinds. `Esc` cancels a tool step and returns to Select. `Ctrl+Z` / `Ctrl+Y` undo and redo; `Ctrl+S` saves (previous file kept as `.bak`); autosave runs every 5 minutes and start-up offers to restore a newer autosave.

| Key | Action | Where |
|---|---|---|
| `Ctrl+N` `Ctrl+O` `Ctrl+S` `Ctrl+Shift+S` | New, Open, Save, Save As | all |
| `Ctrl+L` / `Ctrl+K` | Plot / Arrange for Plot | PDS |
| `Ctrl+I` | Piece Properties | PDS, Grading |
| `1` `2` `3` `5` `6` | Pieces Window, Grading Table, Toolbox, Compare Length, Pieces Table | PDS, Grading |
| `F4` / `Ctrl+Shift+F4` / `Shift+F4` | Base Size only / Small, Big and Base / Sizes Table | PDS, Grading |
| `Z` or `End` | Select tool | PDS, Grading |
| `Alt+1` / `Alt+2` | toggle Grade Point / Curve Point (Optitex NumPad 1 / 2) | PDS, Grading |
| `N` / `Shift+N` | Notch / Notch on Point | PDS |
| `S` / `Shift+S` | Add Seam / Remove Seam; `F5` toggles Cut/Sew line | PDS |
| `Shift+C` `Shift+V` `Shift+X` `Shift+Y` | Copy Grading, Paste Grading, Paste X, Paste Y | Grading |
| `Ctrl+Shift+Alt+R` | Rule Table | Grading |
| `F9` | Start Auto Nesting | Marker |
| Arrows or `2 4 6 8` | nudge selected pieces (Manual Moving Step, default 1 mm) | Marker |
| `R` / `Shift+R` / `F` | next / previous allowed orientation, flip | Marker |
| `Ctrl+C` | Clear Marker (returns all to the Piece Bar; `Ctrl+Z` restores) | Marker |
| `Home` / `Plus` / `Ctrl+-` | Zoom all / in / out | canvas |
| `F5` | Solve | Cut Plan |

Keypad differences from Optitex: `Plus` zooms in, `Ctrl+-` out, `Alt+=` flips horizontally, `F7` zooms by rectangle (egui cannot tell keypad from main row; `docs/spec/07-ui-shell.md` §6.2).

## Workflow 1: import a graded ASTM file and check it (PDS, Grading)

1. Put the `.dxf` and its `.rul` **in the same folder**. The DXF names the table in its `Grade Rule Table:` text; the file must have that name with the `.rul` extension (case does not matter).
2. File › Open on the `.dxf` (or `optirust file.dxf`) opens the import dialog, or File › File Utilities › Import From CAD/CAM Files. Defaults are right for most files: Format auto, Units auto (file, then `$INSUNITS`, then cm), Tolerance 0.5 mm, Curve Points Auto Recognition 3 degrees, notch 7 x 5 mm. Tick **Don't build sizes** only if each block must stay a separate piece.
3. Read the **Import Report** pane that opens after the import. Warnings (approximated, defaulted) are normal; **errors** mean data was lost: say which piece and layer, and ask for a cleaner export. The Style still opens if at least one piece was built. A line "names the grade rule table ... but no rule file was found" means the pieces are **not graded**: fix the folder and reimport.
4. Check: Pieces Window (`1`) lists every piece; Pieces Table (`6`) shows Quantity, Material, area, perimeter. `F4` toggles Base Size only; `Ctrl+Shift+F4` shows small, big and base. Open Grading Table (`2`) on a point to read dX, dY per size (Absolute on = cumulative from the Base Size).
5. Fix what the report names: Notch shapes and depths (`N`, Properties), Seam Allowance (`S`; Properties: width, last width, corner), Grainline direction (`/`), Quantity and Pair.
6. Save as `.optx`.

If a file has no layers 2/3 (no turn/curve flags) the importer guesses Curve Points from turn angles at 3 degrees; check smooth curves.

## Workflow 2: grade (Grading)

Switch to Grading (`Ctrl+Shift+2`). Sizes: Grading › Sizes Table (`Shift+F4`): Insert/Append Sizes, Rename, Set Base Size, Break sizes and Regrade By Break Size, colour and visibility (display only). Grade Rules live on Grade Points (`Alt+1` toggles). Quick edit: select a point, edit the Grading Table cells, `Enter` commits one undoable edit. Copy and reuse: `Shift+C`, then `Shift+V` / `Shift+X` / `Shift+Y` on the target points; Paste Relatively mirrors by piece centre. Rule Table (`Ctrl+Shift+Alt+R`): numbered rules; Apply Rule copies deltas (no live link). Graded Nest view shows all sizes in their colours; Stack Point/Stack by Grainline only changes the display. Sizes that were imported as separate pieces: Graded Nest tool (G29) builds one graded piece (same point count and start point required). Stack Along Line is disabled (not delivered yet).

Export the graded Style for another program: PDS File › File Utilities › Export To CAD/CAM Files. Defaults: ASTM, Grading = Rule file (the `.rul` is written beside the `.dxf`, same stem), Boundary = cut line with sew line on layer 14. Choose Graded nest to get one block per size and no `.rul`, or Base Size only. Read the issue list the export ends with (for example "Box notch written as V" in AAMA).

## Workflow 3: plot pieces 1:1 (PDS)

`Ctrl+L`: choose Pieces (All / On desk / Selected), Sizes, Elements, and Target: **PDF tiled A4** (print on a desktop printer, glue by the assembly map: rows A, B... from the top, columns 1, 2... from the left), **PDF A0**, or **HPGL/2 file**. `Ctrl+K` Arrange for Plot lays pieces out on the sheet width first (gap default 10 mm). Plotter Setup: paper width is the roll width; a plot wider than the paper is refused. Print Working Area (`Ctrl+P`) scales the screen to one A4 page, not 1:1.

## Workflow 4: make a marker (Marker)

1. File › New Marker (`Ctrl+N` in the Marker workspace): Marker Properties: name, Material, **Width** (fabric width between selvedges), **Length** (longest allowed), Plies, Ply mode (only Single in the Marker workspace), margins (waste limits), **Buffer**, shrinkage length/width %, weight, cost per metre. Defaults: width 1500 mm, length 10 000 mm.
2. Marker › Add Style: pick `.optx` files or the open Style. The Style is **embedded**; if the source file later changes, the Marker says "Style changed on disk": use Update from Style.
3. Marker › Order: **Bundles per size** and a direction per size: One Way (all pieces point the same way), Opposite (alternate bundles reversed), Any.
4. Place: drag from the Piece Bar, double-click a thumbnail, Place One Bundle / Place All (bottom-left fill), or auto: Nesting › Auto Nesting Setup (time limit 60 s default, Efficiency limit, Unlimited marker length, Keep placed pieces, Seed) then Start Auto Nesting (`F9`). Same seed and iteration limit repeat a result; a time limit depends on machine speed. Cancel returns the best packing so far.
5. Refine by hand: right-click a piece steps its rotation or flip; right-drag **Shoots** it against neighbours; arrows nudge. Overlaps are allowed and hatched red; pieces inside a margin are outlined orange.
6. Read the status bar: Pieces placed/requested, Bundles, Overlaps (must be 0 before cutting), **Efficiency**, Width, Length, **Per garment** (length / complete bundles). A piece wider than the fabric stays in the Piece Bar.
7. Output: File › Plot (`Ctrl+L`, PDF A0/A4 tiles or HPGL/2; a marker wider than the plotter paper is refused), File › Export Cut File (one generic HPGL/2 file: knife pen 2, drill pen 3; no vendor cutter formats), File › Report to Excel (CSV: General, Order, Pieces, Notches) or Report (PDF with a scaled drawing).

Tips: efficiency rises with more allowed orientations (piece Rotation and Flip rules in Properties), a smaller Buffer and more time; grain rules and One Way direction cost efficiency. Shrinkage enlarges pieces before nesting.

## Workflow 5: plan the cut order (Cut Plan)

1. Cut Plan workspace, Plan pane: **Style** (embedded `.optx`, tick sizes to plan), **Order** (name, client, operator), **Colours and quantities**: one row per colour, one column per size; or Size ratio mode (a ratio per size and a colour total, distributed by largest remainder); or import CSV (header row required: `colour,S,M,L`; unknown sizes are skipped with a message).
2. **Material**: name, width, ply mode, shrinkage, cost per metre, weight. **Marker limits**: max length (default 8000 mm), min and max plies (1 / 50), max bundles per marker (8), waste limit %, end allowance per ply (20 mm). **Cost**: estimated efficiency (82 %), material share of production cost (60 %), Nest markers (real nesting per marker, 20 s each by default).
3. Solve (`F5`, or toolbar). The Results view lists markers (ratio, length, efficiency), lays (colour, plies), fabric per colour and total, and a size x colour table of ordered / planned / difference. Over-cut inside the deviation allowance is normal; a badge marks over-cut and a marker "too long". Lengths in italics with "est." are estimates until Nest Markers runs.
4. Edit if needed: Lay plies or a marker ratio by hand; the plan shows "edited" and Solve asks before discarding.
5. **Cut Order** pane (tab next to Results): add **Fabric Rolls** (code, colour, shade, width, length; or import a roll CSV with columns Roll, Colour, optional Shade, Width, Length and units like `Width (cm)`). The **Spreading steps** table gives the order: colours in Order sequence, longest ply first, roll to draw from, plies, fabric, left on roll. Badges: "shade change" (a lay mixes shades because no single shade could complete it), "missing" (not enough fabric, with a Missing fabric table). **Remnant** is what returns to the fabric room. Rolls narrower than the Material width stay unused ("too narrow").
6. Reports: Report (CSV, one file per section) and Report (PDF); Production Report for the cutting floor (no costs, lengths in `m cm`). With rolls, both add Cut order, Fabric rolls and Missing fabric sections. Save Markers writes one `.optm` per nested marker.

## What optirust does not do (1.0.0): say so plainly

Stripe and plaid matching, tilt, block fuse, flaws, cross grading, multi-dimensional size systems, Stack Along Line, several Styles or mixed Materials in one Cut Plan, vendor cutter drivers (generic HPGL/2 only), digitizer, 3D, reading Optitex native files. Windows 7 is verified under Wine only, not on hardware. The Indonesian wording is unconfirmed by an Operator: take corrections. Full list: `ROADMAP.md`, `docs/parity-checklist.md`.

## Rules for the assistant

1. Give menu path and shortcut together; shortcuts above are the defaults and can be rebound.
2. Never invent a menu item: if unsure, tell the Operator to open the command palette (`Ctrl+Shift+P`) and search, or `F1`.
3. Never edit the Operator's files by hand; guide them through the app. For scripted work use `optirust-headless`.
4. Quote numbers with units (mm, cm, m) and state the working unit; the app stores millimetres and shows the unit chosen in Preferences (`|`).
