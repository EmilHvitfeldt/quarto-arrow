# Arrow Extension Roadmap

## Completed

- [x] Basic arrow rendering (SVG)
- [x] Straight lines
- [x] Quadratic Bezier curves (1 control point)
- [x] Cubic Bezier curves (2 control points)
- [x] Color customization
- [x] Stroke width customization
- [x] Arrowhead size customization
- [x] Inline positioning (default)
- [x] Fixed positioning (viewport-relative)
- [x] Absolute positioning (container-relative)
- [x] HTML format support
- [x] Text fallback for other formats
- [x] Arrowhead placement (`head-start`, `head-end`)
- [x] Arrowhead styles (`head="arrow|stealth|diamond|circle|square|bar|barbed|none"`)
- [x] Outline vs filled arrowheads (`head-fill`)

## Known Issues

- **PDF output not working** - SVG arrows don't render in PDF. Needs TikZ or alternative backend.
- **Percentage-based coordinates** - Implemented but arrows render off-screen due to `scrollWidth` vs `innerWidth` mismatch. See `docs/positioned-arrows-investigation.md` for details.

## Planned Features

### Arrowhead Options
- [x] `head-start="true"` - arrowhead at start
- [x] `head-end="true"` - arrowhead at end (current default)
- [x] Arrowhead styles via `head="..."`:
  - [x] `none` - no arrowhead
  - [x] `arrow` - default filled triangle
  - [x] `stealth` - pointed, angular military-style
  - [x] `barbed` - hook-like, fishing arrow style
  - [x] `diamond` - diamond/rhombus shape
  - [x] `circle` / `dot` - round endpoint
  - [x] `square` - square endpoint
  - [x] `bar` / `stop` - flat perpendicular line
- [x] `head-fill="true|false"` - filled vs outline for applicable styles
- [x] `head-size` - independent arrowhead sizing (not tied to stroke width)

### Line Styles
- [x] `dash="true"` or `dash="5,3"` - dashed lines
- [x] `opacity="0.5"` - line transparency
- [x] `line="dot"` - dotted lines
- [x] `line="double"` - parallel double line
- [x] `line="triple"` - parallel triple line

**Not planned:** `wavy`, `zigzag`, custom SVG patterns (too complex - requires path transformation)

### Convenience & Shortcuts
- [x] `bend="left|right|angle"` - auto-calculate curve direction
- [x] `curve="0.5"` - simple curviness parameter (0=straight, 1=max curve) instead of manual control points
- [ ] `style="..."` presets:
  - [ ] `annotation` - subtle, thin, for callouts
  - [ ] `flowchart` - clean, professional
  - [ ] `hand-drawn` - sketchy, organic feel
  - [ ] `technical` - precise, engineering style
- [ ] Relative coordinates: `to="+100,+50"` relative to `from`
- [ ] Percentage units: `from="10%,20%"` relative to container
- [ ] `class="..."` - add custom CSS classes for external styling

### Accessibility
- [ ] `aria-label="..."` - screen reader description
- [ ] `alt="..."` - alternative text description
- [ ] `role="img"` - proper ARIA role on SVG
- [ ] `title="..."` - tooltip/accessible name
- [ ] Respect `prefers-reduced-motion` for animations
- [ ] High contrast mode support

### Labels
- [x] `label="text"` - text along the arrow
- [x] `label-position="start|middle|end"` - where to place label
- [x] `label-offset="10"` - distance from line

### Advanced Curves
- [x] Multiple waypoints for complex paths (`waypoints` parameter with Catmull-Rom smoothing)
- [ ] Arc segments (circular curves)
- [x] Auto-curve based on distance/direction (`curve` + `bend` parameters)

### Animation (HTML only)
- [ ] `animate="true"` - draw animation on load
- [ ] `animate-duration="1s"` - animation speed
- [ ] `animate-delay="0.5s"` - start delay

### Format Support
- [ ] PDF support (TikZ backend) - currently broken
- [ ] DOCX support
- [x] RevealJS presentation support

## Typst Support

Typst is a modern typesetting system with native vector graphics capabilities.

### Implementation Approaches

| Approach | Description | Pros | Cons |
|----------|-------------|------|------|
| **Raw Typst paths** | Generate native `path()` commands | Native rendering, no dependencies | Limited feature set |
| **CeTZ package** | Use the CeTZ drawing library | Rich features, proper arrowheads | Requires package import |
| **SVG embed** | Embed SVG via `image.decode()` | Reuse existing SVG code | May have rendering quirks |

### Planned Typst Features
- [ ] Detect Typst format via `quarto.doc.isFormat("typst")`
- [ ] Generate native Typst path syntax
- [ ] Support Typst units (`pt`, `cm`, `mm`, `em`, `%`)
- [ ] Typst color syntax support
- [ ] CeTZ integration for advanced features:
  - [ ] Native arrowhead marks
  - [ ] Bezier curves via `bezier()`
  - [ ] Coordinate transformations

### Typst Path Syntax Reference

```typst
// Basic path
#path(
  stroke: 2pt + black,
  fill: none,
  closed: false,
  // Points with control handles: (point, pre-control, post-control)
  ((0pt, 0pt), auto, (20pt, -10pt)),   // start
  ((100pt, 50pt), (80pt, 60pt), auto), // end
)

// With CeTZ package
#import "@preview/cetz:0.2.0"
#cetz.canvas({
  import cetz.draw: *
  bezier((0, 0), (3, 1), (1, 2), (2, -1), mark: (end: ">"))
})
```

### Typst-Specific Parameters
- [ ] `typst-stroke="2pt + blue"` - override stroke for Typst
- [ ] `typst-unit="pt|cm|mm"` - coordinate unit for Typst output

## API Design Notes

### Current Parameter Structure
```
{{< arrow
    from="x,y" to="x,y"           # Required endpoints
    control1="x,y" control2="x,y" # Optional curve control
    color="..." width="..." size="..." # Styling
    position="fixed|absolute"     # Positioning mode
>}}
```

### Proposed Additions
```
{{< arrow
    ...existing...

    # Arrowheads
    start="true" end="true"       # Arrowhead placement
    head="stealth"                # Arrowhead style
    head-size="12"                # Independent head sizing

    # Line styles
    dash="5,3"                    # Line pattern
    pattern="wavy"                # Custom pattern
    opacity="0.8"                 # Transparency

    # Convenience
    direction="right"             # Auto-curve direction
    curve="0.5"                   # Simple curviness
    style="annotation"            # Preset style
    to="+100,+50"                 # Relative coordinates

    # Accessibility
    aria-label="Arrow to button"  # Screen reader text
    alt="Navigation arrow"        # Alt text

    # Labels & animation
    label="Click here"            # Text label
    animate="true"                # Animation
>}}
```

## Code Architecture

```
arrow.lua
├── parse_point()        # Parse "x,y" strings
├── generate_arrow_id()  # Unique marker IDs
├── arr_min/arr_max()    # Bounding box helpers
└── arrow()              # Main shortcode function
    ├── Parse arguments
    ├── Calculate bounding box
    ├── Build SVG path
    ├── Generate marker definition
    ├── Wrap in container (if positioned)
    └── Return format-appropriate output
```

Future refactoring considerations:
- Extract SVG generation into separate function
- Extract marker generation for multiple head styles
- Add validation/error handling module
- Consider config file for defaults
