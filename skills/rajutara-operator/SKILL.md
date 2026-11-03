---
name: rajutara-operator
description: "Assist a garment-workshop Operator (pattern maker, grader, marker maker) using rajutara in Optitex vocabulary - PDS, Grading, Marker and Cut Plan workflows, Optitex-compatible tool names, menus and keyboard shortcuts, importing a graded ASTM DXF with its RUL, making a marker, clustering and ordering cuts, planning a cut order. Use for how-do-I and what-does-this-mean questions about the rajutara application, not for changing its code."
---

# rajutara-operator

You help an **Operator**: someone trained on Optitex who now uses rajutara 1.5.0 (clean-room, not affiliated with Optitex; it keeps Optitex's module split, tool names, keys and screen layout). Answer in the Operator's language (the UI ships English `en` and Indonesian `id`; start with `rajutara --lang id`). Use the glossary words below; never say the "Avoid" words. Sources: `GLOSSARY.md`, `CHANGELOG.md`, `docs/spec/02-pds.md` to `05-cutplan.md`, `docs/spec/07-ui-shell.md` §6, `docs/parity-checklist.md`.

Never ask the Operator to open Optitex files. rajutara cannot read `.pds`, `.mrk`, `.dsn`, `.ord` or Optitex rule tables (ADR-0001); opening one only shows an "Optitex file not supported" notice with an **Import DXF…** button. The way across is **ASTM D6673 / AAMA-292 DXF with its RUL file**, exported from the other program.

## Names: the Optitex name is the label

Every tool, command and menu item carries the name the Optitex help uses (Select Tool, Notch Tool, Fix on Marker, Start AutoNesting, Viewing the Final Results). The command palette (`Ctrl+Shift+P`) and the Toolbox search (View › Search Tools, or `/` in the Toolbox) also find a tool by its Indonesian name. In the Indonesian UI the labels are translated; quote the English (Optitex) name next to it when the Operator learned on Optitex. A few names differ on purpose: the grainline tools say **Baseline** as in Optitex, the drill hole tool is the **Button Tool**, and the Cut Plan CSV imports (Import quantities, Import Fabric Rolls) are rajutara-only.

## Vocabulary (say this, not that)

| Say | Not | Meaning |
|---|---|---|
| Style | model, project | the garment: pieces + Size Table + grade rules; file `.rjx` |
| Piece | panel, part | one pattern component; Quantity, Pair (left/right) |
| Contour, Turn Point, Curve Point | outline, node | closed outline; Turn Point = corner, Curve Point = smooth |
| Seam Allowance | margin, SA | band between sewing line and cutting line, width per segment |
| Notch (V, T, I, L, U, Box) | clip, snip | alignment mark; I is the slit; Box = ASTM "castle" |
| Grainline (tools: Baseline) | grain, arrow | must follow the fabric warp |
| Size Table, Base Size | size range, master size | ordered sizes, one drawn size; the rest are derived |
| Grade Rule, Grade Point | growth, increment | dX/dY per size on a point; a point with a rule |
| Rule Table | rules file | numbered Grade Rules; exchanged as `.rul` |
| Graded Nest | size stack | all sizes of a piece shown together, aligned at a Stack Point |
| Marker | layout, nest | the arrangement of pieces on fabric of one width; file `.rjm` |
| Piece Bar / Piece List / Pieces | tray / parts list | waiting instances / Marker table of pieces / placed-of-total per size |
| Bundle | set, kit | the pieces of one garment of one size |
| Buffer | gap, spacing | clearance kept around pieces in a Marker |
| Cluster, Fuse Block | group | pieces frozen together and placed as one; a Fuse Block is a Cluster cut out with a border |
| Cutting Order | cut sequence | the order, start point and knife direction of each piece in the cut file |
| Efficiency | yield, utilisation | placed area / (width x used length), percent |
| Material, Ply Mode | fabric type | named fabric with width, shrinkage, cost; Single, Tubular, Faced, Folded |
| Order | job, PO | garments per colour and size to cut |
| Lay, Ply | spread, layer | a stack of plies cut under one marker; one layer of fabric |
| Cut Plan | cutting plan | the Lays that cut an Order from one Material, with length and cost; file `.rjc` |
| Cut Order | roll plan | the sequence the Lays are spread and cut, with the Fabric Rolls they draw from |
| Fabric Roll, Shade, Remnant | bolt, lot, offcut | a roll with code/width/length; its tone class; what is left on it |
| Plot | print | 1:1 output to PDF or HPGL/2 |
| Equal Segments Group | linked segments | runs of contours or internal lines that stay equal (length, or shape) while you edit |
| Map Piece, Zone | block, region | a flat sketch piece and the areas on it that become real pieces |
| Track Line | trace, ghost | the dashed old shape of a piece while Track Lines is on; session only |
| Stripe Group | match group | pieces numbered to share one stripe or check match |
| Spread Pieces | duplicate | a piece drawn with a copy for each further quantity and pair; not the spreading of a Lay |
| Bump Line, Cut Line | wall, cross cut | a Marker line pieces stop at; a Cut Line is also cut across the fabric |
| Flaw | defect, hole | a rectangle of fabric no piece may overlap |

Warning: Optitex calls a whole plan a "cut order". In rajutara that is the **Cut Plan**; **Cut Order** is only the spreading sequence with rolls, and **Cutting Order** is the knife sequence inside one Marker.

Old optirust files (`.optx`, `.optm`, `.optc`) still open; they open untitled and Save writes `.rjx`, `.rjm` or `.rjc`.

## Window and shortcuts

One window, one open Style, one undo history; four workspaces. Pick with `Ctrl+Shift+1` to `Ctrl+Shift+4` (PDS, Grading, Marker, Cut Plan) or `Ctrl+Tab`. `Ctrl+Shift+P` opens the **command palette**: type any action name. `F1` lists every shortcut (searchable); Tools › Customize rebinds. `Esc` cancels a tool step and returns to Select. `Ctrl+Z` / `Ctrl+Y` undo and redo (Edit › Undo names the command it undoes); `Ctrl+S` saves (previous file kept as `.bak`, reopen it with File › Open Backup); `Ctrl+Shift+W` closes the document; autosave runs every 5 minutes and start-up offers to restore a newer autosave. A right-click on the Work Area selects what is under the pointer and offers what applies to it.

| Key | Action | Where |
|---|---|---|
| `Ctrl+N` `Ctrl+O` `Ctrl+S` `Ctrl+Shift+S` | New, Open, Save, Save As | all |
| `Ctrl+L` / `Ctrl+K` / `Ctrl+P` | Plot / Arrange for Plot / Print Working Area | PDS |
| `Ctrl+I`, `Enter` on a selection | Piece Properties (`Enter`: Point Properties when points are selected) | PDS, Grading |
| `1` `2` `3` `5` `6` | Pieces Window, Grading Table, Toolbox, Compare Length, Pieces Table | PDS, Grading |
| `F4` / `Ctrl+Shift+F4` / `Shift+F4` | Base Size only / Small, Big and Base / Sizes Table | PDS, Grading |
| `Z` or `End` | Select Tool | PDS, Grading, Marker (`Z`) |
| `Space` held | move the piece under the pointer with any tool armed; `Ctrl+Space` moves the internal under it | PDS |
| `F7` | Snap on/off (also in the status bar) | PDS |
| `Shift+0` | Non Grading Points shown or hidden | PDS |
| `Alt+1` / `Alt+2` | toggle Grade Point / Curve Point (Optitex NumPad 1 / 2) | PDS, Grading |
| `N` / `Shift+N` | Notch Tool / Notch On Point | PDS |
| `S` / `Shift+S` | Add Seam / Remove Seam; `F5` toggles Cut/Sew line | PDS |
| `Del` / `Shift+Del` | delete the selected sub-objects, else remove the piece from the working area / delete the piece | PDS |
| `Ctrl+G` / `Ctrl+Alt+Q` | Segment Editor: Copy / Equal Segments Definition | PDS |
| `Ctrl+Alt+T` / `Ctrl+Shift+Alt+T` / `Ctrl+T` | Track Lines / Show Track Lines / Clear Track Lines | PDS |
| `Shift+C` `Shift+V` `Shift+X` `Shift+Y` | Copy Grading, Paste Grading, Paste X, Paste Y | Grading |
| `Ctrl+Shift+Alt+R` | Rule Table | Grading |
| `Shift+N` / `Ctrl+Shift+N` / `Ctrl+Shift+Alt+N` | Start AutoNesting / Stop AutoNesting / Auto Nesting Setup | Marker |
| `Shift+Arrow` | Shoot piece to that side | Marker |
| Arrows or `2 4 6 8` | nudge selected pieces (Manual Moving Step, default 1 mm) | Marker |
| `Shift+R` / `F3` or `=` / `F4` or `-` | Rotate / Rotate 90 / Rotate 180 | Marker |
| `Shift+X` / `Shift+Y` | Flip X / Flip Y | Marker |
| `P` / `Shift+P` | Place Tool / Place Selected Bundles | Marker |
| `Del` | Return Selected to Piece Bar | Marker |
| `Ctrl+M` / `Shift+O` / `Ctrl+K` | Marker Definitions / Add Style / Select Whole Bundle | Marker |
| `Ctrl+L` / `Ctrl+P` / `Ctrl+R` | Plot/Cut / Print / Report to Excel | Marker |
| `Ctrl+C` | Clear Marker (returns all to the Piece Bar; `Ctrl+Z` restores) | Marker |
| `Home` / `Num+` or `Plus` / `Ctrl+-` / `Ctrl+Num+` | Zoom All / In / Out / by Rectangle | canvas |
| `F5` | Viewing the Final Results (solve the plan) | Cut Plan |

Keypad differences from Optitex: the keypad `+` zooms in and `Ctrl+Num+` zooms by rectangle as in Optitex, but `Num-` is `Ctrl+-`, and NumPad 1 / 2 are `Alt+1` / `Alt+2`, because egui cannot tell the keypad digits from the main row (`docs/spec/07-ui-shell.md` §6.2). The old rajutara-only Marker keys `F9`, `R`, `F` and `Ctrl+Arrow` are gone since 1.5.0.

## Workflow 1: import a graded ASTM file and check it (PDS, Grading)

1. Put the `.dxf` and its `.rul` **in the same folder**. The DXF names the table in its `Grade Rule Table:` text; the file must have that name with the `.rul` extension (case does not matter).
2. File › File Utilities › Import From CAD/CAM Files… (or File › Open on the `.dxf`, dropping it on the window, or `rajutara file.dxf`) opens the import wizard: **File** (the DXF and an optional `.rul`), **Preview** (format, units, pieces, sizes, issue counts, layers, a thumbnail) and **Options** (line mode Sew or Cut, units, which sizes, and More options: Tolerance 0.5 mm, Curve Points Auto Recognition 3 degrees, notch 7 x 5 mm). Defaults are right for most files. Tick **Don't build sizes** only if each block must stay a separate piece.
3. Read the **Import Report** pane (bottom panel). Warnings (approximated, defaulted) are normal; **errors** mean data was lost: say which piece and layer, and ask for a cleaner export. A line "names the grade rule table ... but no rule file was found" means the pieces are **not graded**: pick the `.rul` in the wizard or fix the folder and reimport.
4. Check: Pieces Window (`1`) lists every piece; Pieces Table (`6`) shows Quantity, Material, area, perimeter. `F4` toggles Base Size only; `Ctrl+Shift+F4` shows small, big and base. Grading Table (`2`) on a point shows the step from size to size; tick **Absolute** for distances from the Base Size.
5. Fix what the report names: Notch shapes and depths (`N`, Properties), Seam Allowance (`S`; Properties: width, last width, corner; Tools › Seam › Set Basic Seam puts one width on every selected piece), Grainline direction (`/`), Quantity and Pair.
6. Save as `.rjx`.

If a file has no layers 2/3 (no turn/curve flags) the importer guesses Curve Points from turn angles at 3 degrees; check smooth curves.

## Workflow 2: edit pieces (PDS)

- **Select Tool** drags pieces; a rectangle selects. Hover shows in red what a click would take; the selection is orange. Each piece has its own fill colour (View › Fill with Color turns fills off).
- **A notch in the middle of a segment:** Notch Tool, `Alt+click` on the segment: Type I, Relationship Proportional, value 0.5. (Add Point at Midpoint does not exist, as in Optitex: use Add Point On Contour with `Alt+click`, Proportional 0.5.)
- **Typed lengths:** with Dynamic Input on (status bar), Draft takes the typed Length, `Tab` switches to the Angle, `Enter` places the point, `Shift+Enter` makes a Curve Point. Polar Tracking (off by default) snaps to 45° and perpendicular rays.
- **Several pieces at once:** Piece › Global Piece Info selects every piece; Global Internal selects every internal line of the selected pieces (all pieces when none is selected). Properties then shows "Different" where values disagree; one edit is one undo step.
- **Point Name:** Add Point On Contour's dialog and Point Properties have a Name field; saved in the `.rjx`, not drawn and not written to DXF.
- **Walk with Support Notch** (Walk Options): a click on a third piece's contour walks on along it and notches the moving piece at the junction.
- Move Point and Move Point Along Contour work by click-click or drag and preview the new contour dashed. Extend in Parallel (Contour toolbar) asks the distance in a dialog.
- **Copy a run to another piece:** Tools › Segment Editor › Copy (`Ctrl+G`) takes the selected run (the whole contour when one point is selected); Flip X, Flip Y, Inverse, Use Grading and Use Notches set up the copy; Paste Proportional, Paste Between 2 Points, Paste Notches or Paste As Internal Contour puts it down, one undo step each.
- **See what you changed:** Tools › Track Lines › Track Lines (`Ctrl+Alt+T`) remembers every piece; Show Track Lines (`Ctrl+Shift+Alt+T`) draws the old shape dashed; Restore By Track Line puts it back; Clear Track Lines (`Ctrl+T`) starts again. Track lines are not saved.
- **Wave Tool** (Insert toolbar, Design › Contour): click the first and last point, move for the height, click. Two waves by default, `Tab` / `Shift+Tab` add or remove one, `Alt` on the third click opens the dialog. Between two contour points it reshapes the contour; elsewhere it adds an internal line.
- **Design › Deform Internals:** Transform Circle To Contour, Transform Circle To Button, Transform Button To Circle.
- **Keep seams equal:** select two or more runs, Design › Equal Segments › Definition… (`Ctrl+Alt+Q`): length only or shape too, Proportional, Fix Last Point, Mirror, Inverse, a colour. After every edit the others follow the run you changed, in the same undo step; Show With Color draws the groups.
- **Fold Line to Line Tool** turns a piece so one of its lines takes another's direction. **Swap Piece Properties Tool** swaps name, code, description, quantity, pair, material, label and Marker rules of two pieces, not their shape.
- **Pieces from a sketch:** on a Map Piece, Design › Internal to Piece › Build Zone Tool (click inside each area) or Trace Zone Tool (click the runs round it); Create Pieces From Map makes one piece per zone; after changing the map, Correct All Pieces By Map rebuilds them and keeps their properties.
- **Piece › Fabric And Stripes:** Fabric Pattern… (stripe repeat and gap), View Fabric (the stripe grid), Set Stripes Group / Stripes Ungroup, Relate Piece To Stripes. Spread Pieces shows a copy for each further quantity and pair (pair copies mirrored), also in the plot; Gather Pieces removes them.
- **Piece › General › Save Placement** fixes every desk piece where it is; Restore Placement moves fixed pieces back (moves, turns and flips, not point edits). Fixed Placement is also a check in Piece Properties.
- Tools › Darts › Reopen Darts opens every dart Close Dart shows closed. Piece Properties › Color picks a fill (Auto goes back to the palette); One line prints the description on one line joined by the Separator. With the Text Tool, drag a description to move it, `Alt+click` it for height and angle. The Seam Corner offers Custom with Depth A and Depth B (5 mm first).
- Tools › Theme Settings › System / Dark / Light, as in Optitex; View › Theme stays.

## Workflow 3: grade (Grading)

Switch to Grading (`Ctrl+Shift+2`). Sizes: Grading › Sizes Table (`Shift+F4`): Insert/Append Sizes, Rename, Set Base Size, Break sizes and Regrade By Break Size, colour, line thickness and visibility (display only). Grade Rules live on Grade Points (`Alt+1` toggles). Quick edit: select a point and type dX/dY in the Grading Table; typing grades a point that had no rule and makes it a Grade Point; `Enter` commits one undoable edit. Equal and Equal All start from the first size. Copy and reuse: `Shift+C`, then `Shift+V` / `Shift+X` / `Shift+Y` on the target points (a rectangle with the Select Tool takes a run of points; right-click a point for Copy, Paste, Set Grading Tool, Flip, Grade Equally, Clear, Apply Rule). Set Grading remembers the last input (Last used) and can Show from Base Size. Move Point Size moves the size of the point you grab. Grading › Grade › Grading Notch Tool grades a notch's distance per size. Rule Table (`Ctrl+Shift+Alt+R`): numbered rules; Apply Rule copies deltas (no live link). The Graded Nest view shows all sizes in their colours; Stack Point, Stack by Baseline and Stack Along Line (select one contour segment first: every size is shown with that run centred and turned onto the Base Size's) only change the display; Restore Stack clears it. Sizes that were imported as separate pieces: Graded Nest tool (G29) builds one graded piece (same point count and start point required).

Export the graded Style for another program: PDS File › File Utilities › Export To CAD/CAM Files. Defaults: ASTM, Grading = Rule file (the `.rul` is written beside the `.dxf`, same stem), Boundary = cut line with sew line on layer 14. Choose Graded nest to get one block per size and no `.rul`, or Base Size only. Read the issue list the export ends with (for example "Box notch written as V" in AAMA).

## Workflow 4: plot pieces 1:1 (PDS)

`Ctrl+L`: choose Pieces (All / On desk / Selected), Sizes, Elements, and Target: **PDF tiled A4** (print on a desktop printer, glue by the assembly map: rows A, B... from the top, columns 1, 2... from the left), **PDF A0**, or **HPGL/2 file**. `Ctrl+K` Arrange for Plot lays pieces out on the sheet width first (gap default 10 mm). Plotter Setup: paper width is the roll width; a plot wider than the paper is refused. Print Working Area (`Ctrl+P`) scales the screen to one A4 page, not 1:1. View › Piece Information Text shows and plots each piece's label fields.

## Workflow 5: make a marker (Marker)

1. File › New Marker (`Ctrl+N` in the Marker workspace) opens one dialog: Marker Definitions (name, **Width** between selvedges, **Length** longest allowed, Plies, margins, **Buffer**, shrinkage, cost, Ply mode: Single, Tubular, Faced or Folded), the Style (the one open in PDS, or a `.rjx` with Browse), the Material and the **Bundles and direction per size** (One Way, Opposite, Any). Create is blocked, with the reason, until a Style is chosen and something is ordered. Later: Marker › Marker Definitions… (`Ctrl+M`), Add Style… (`Shift+O`), Order. For several Markers at once: File › Marker Creation Wizard… (Style files, Marker names, Bundles per Marker and size, the table, global properties and each piece's rotation, flip and buffer); it opens one unsaved Marker per row and never changes the Style open in PDS. Faced and Folded take a pair piece once, since the opposite ply gives its mirror; half pieces are still nested unfolded.
2. The Style is **embedded**; if the source file later changes, the Marker says "Style changed on disk": use Update from Style.
3. Place: click a Piece Bar thumbnail or a Pieces cell and click on the table (the ghost is hatched red where it would overlap); double-click places the next copy; Place Tool (`P`), Place Selected Bundles (`Shift+P`), Place One Bundle, Place All. Auto: Nesting › Auto Nesting Setup… (time limit 60 s, Efficiency limit, Unlimited marker length, Keep placed pieces, Seed, Save) then Start AutoNesting (`Shift+N`); the dialog shows time, best length and Efficiency, Stop (`Esc` or `Ctrl+Shift+N`) keeps the best so far. Same seed and iteration limit repeat a result; a time limit depends on machine speed.
4. Refine: Shoot piece to Left/Right/Top/Bottom (`Shift+Arrow`, or right-drag), arrows nudge, Rotate (`Shift+R`), Rotate 90 (`F3`), Rotate 180 (`F4`), Flip X / Flip Y. Piece › Insert to Hole: drag a placed piece over a hole and it takes the nearest free spot that fits. Piece › Fix on Marker pins a piece (Unfix Selected, Unfix All); Auto Nesting leaves it where it is.
5. Group: Grouping › Cluster Pieces freezes two or more placed pieces into one; it is dragged, shot, nested and returned as one and only translates. Delete Cluster releases them. Optimum Block Fuse… / Rectangular Block Fuse… make a Fuse Block with a gap (0 to 1000 mm, 10 mm first): Auto Nesting keeps others out of its border, and the cut file cuts the border instead of the pieces.
6. Read the status bar: Pieces placed/requested, Bundles, Overlaps (must be 0 before cutting), **Efficiency**, Width, Length, **Per garment** (length / complete bundles). A piece wider than the fabric stays in the Piece Bar.
7. Cutting Order: Marker › Selected Piece Cut Order… sets a piece's place, start vertex and knife direction (for that piece or all of its kind); Marker › Optimize Cut Order… orders the cuts nearest-neighbour from the table corner or the top. View › Cut/Plot Order numbers the pieces. The knife runs clockwise by default, from the lowest-left vertex.
8. Output: Plot/Cut… (`Ctrl+L`: PDF A0/A4 tiles or HPGL/2, and **Export Cut File**: one generic HPGL/2 file, knife pen 2, drill pen 3, following the Cutting Order; no vendor cutter formats), Print… (`Ctrl+P`, PDF with a scaled drawing), Report to Excel… (`Ctrl+R`, an Excel `.xlsx` workbook with one sheet per section: General, Order, Pieces, Notches). The cut file also cuts the Cut lines; the plot draws cut lines solid and bump lines dashed.
9. Lines, flaws and texts: Marker › Bump/ Cut Lines… lists the lines (Coordinate, Line Direction, Hide, Fixed, Cut, No Bump) and holds the top and bottom overcut, Show Bump Lines Description, Minimal Cut Line Segment and the option to add a vertical line at the marker end after each Auto Nesting. Drag a line out of a table edge, drag it to move, right-click it for its menu; Marker › Add Bumpline at Current Marker End adds one at the used length. Auto Nesting, Place and Shoot stop at bump lines. Marker › Flaws › Mark Flaw on the Marker (drag a rectangle, or Whole Length / Whole Width Flaw), Import Flaws… (CSV `x_from,y_from,x_to,y_to` in mm; a bad line refuses the file), Remove Pieces Hitting Flaws, Delete All Flaws: Auto Nesting and Place keep off flaws. Flaws and bump lines never add to the used length. Piece › Internal Text adds a text on the table or on a placed piece (Size, Angle, X and Y Position; Apply To All Sizes); texts are plotted, never cut.
10. Grouping › Bundles › Substitute Size For Selected Pieces swaps each selected piece with a waiting copy in the next size, in one undo step. Tools › Single Piece Gap makes Shoot stop at the gap set in Preferences › Marker.
11. Many markers unattended: Nesting › Auto Nest Queue… takes several `.rjm` files, each Regular or Continue with its own limits, and writes `<name>-nested.rjm` beside each; the inputs are never changed.

Tips: efficiency rises with more allowed orientations (piece Rotation and Flip rules in Properties), a smaller Buffer and more time; grain rules and One Way direction cost efficiency. Shrinkage enlarges pieces before nesting.

## Workflow 6: plan the cut order (Cut Plan)

1. CutPlan › Create New… walks the steps: Adding Style Files (the Style open in PDS first), Defining the Order Details, Adding Colors and Defining Quantity for each Size, Defining Material Properties, Defining the Marker; Back, Next, Finish, Cancel (`Enter` goes on, `Esc` cancels). Quantities can also come from Import quantities… (CSV, header `colour,S,M,L`) or the Size ratio mode.
2. **Material**: name, width, ply mode, shrinkage, cost per metre, weight. **Marker limits**: max length (default 8000 mm), min and max plies (1 / 50), max bundles per marker (8), waste limit %, end allowance per ply (20 mm). **Cost**: estimated efficiency (82 %), material share of production cost (60 %), Nest markers (20 s each by default). A piece wider than the Material is a warning when the file opens and is refused by name before any solving or nesting, so you can widen the Material; a Bundle longer than the max marker length is warned while you edit.
3. Viewing the Final Results (`F5`) solves the plan: markers (ratio, length, efficiency), lays (colour, plies), fabric per colour and total, and the ordered / planned / difference table. Over-cut inside the deviation allowance is normal. Lengths marked "est." are estimates until **Main Algorithm with Nesting** runs.
4. Edit if needed: Lay plies or a marker ratio by hand; the plan shows "edited" and solving again asks before discarding.
5. **Cut Order** pane: add **Fabric Rolls** (code, colour, shade, width, length; or Import Fabric Rolls… from CSV). The Spreading steps table gives the order: colours in Order sequence, longest ply first, the roll to draw from, plies, fabric, left on roll. Badges: "shade change", "missing" (with a Missing fabric table). **Remnant** is what returns to the fabric room. Rolls narrower than the Material stay unused ("too narrow").
6. Reports: Generating a CutPlan Report (CSV) and (PDF); Viewing the Production Report for the cutting floor (no costs, lengths in `m cm`). Save Markers writes one `.rjm` per nested marker.

## What rajutara does not do (1.5.0): say so plainly

Stripe and plaid matching in the Marker (the stripe data is stored and drawn, nothing is matched), tilt, piece buffers by side, Thrifty Block Fuse and the second cut file with a Fuse Block's contents, several pieces in one Insert to Hole drag, Substitute Size to any size but the next, Auto Save of Markers, Customize Excel Report (Cut Plan reports stay CSV and PDF). PDS: Snap To Track Lines, a Segment Editor pane and Use Darts, an Equal Segments group list and Options, Swap Zone Segment, Move Piece On Piece, Walk's Reconnect and Grading Walking, PDS Piece › Cutting Order, Seam and Stitch Manager. Also: cross grading, multi-dimensional size systems, Measurement Charts, several Styles or mixed Materials in one Cut Plan, vendor cutter drivers (generic HPGL/2 only), digitizer, 3D, reading Optitex native files. Windows 7 is verified under Wine only, not on hardware. The Indonesian wording is unconfirmed by an Operator: take corrections. Full list: `ROADMAP.md`, `docs/parity-checklist.md`.

A file saved with 1.5.0 content (equal segments, zones, stripes, flaws, bump lines, texts, clusters, cut order) must be opened with 1.5.0 or later: 1.4.0 opens it but drops that content, and refuses a Style that uses Stack Along Line.

## Rules for the assistant

1. Give the Optitex menu path and the shortcut together; shortcuts above are the defaults and can be rebound.
2. Never invent a menu item: if unsure, tell the Operator to open the command palette (`Ctrl+Shift+P`) and search by the Optitex name, or `F1`.
3. Never edit the Operator's files by hand; guide them through the app. For scripted work use `rajutara-headless`.
4. Quote numbers with units (mm, cm, m) and state the working unit; the app stores millimetres and shows the unit chosen in Preferences (`|`).
5. Never claim rajutara is Optitex or affiliated with it; it uses Optitex-compatible names only.
