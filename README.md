# Quarto Arrow Extension

A Quarto shortcode extension for drawing curved SVG arrows in documents.

## Installation

```bash
quarto add emilhvitfeldt/quarto-arrow
```

## Usage

```markdown
{{< arrow from="x1,y1" to="x2,y2" >}}
```

## Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `from` | Yes | - | Start point coordinates `"x,y"` |
| `to` | Yes | - | End point coordinates `"x,y"` |
| `control1` | No | - | First control point for curve `"x,y"` |
| `control2` | No | - | Second control point for S-curves `"x,y"` |
| `color` | No | `black` | Stroke and arrowhead color |
| `width` | No | `2` | Stroke width in pixels |
| `size` | No | `10` | Arrowhead size |
| `position` | No | - | CSS positioning: `"fixed"` or `"absolute"` |

## Curve Types

### Straight Line
No control points - draws a direct line between points.

```markdown
{{< arrow from="50,50" to="250,50" >}}
```

### Quadratic Bezier
One control point - creates a simple curve.

```markdown
{{< arrow from="50,50" to="250,50" control1="150,120" >}}
```

The curve is "pulled" toward the control point. Place it above the line for an upward curve, below for a downward curve.

### Cubic Bezier
Two control points - creates S-curves and complex shapes.

```markdown
{{< arrow from="50,50" to="250,150" control1="150,0" control2="150,200" >}}
```

`control1` influences the curve near the start point, `control2` influences it near the end.

## Positioning Modes

### Inline (default)
Arrow is part of document flow, sized to fit its bounding box.

```markdown
{{< arrow from="50,50" to="250,50" control1="150,120" >}}
```

### Fixed (`position="fixed"`)
Positioned relative to the viewport. Coordinates are screen pixels. No wrapper needed.

```markdown
{{< arrow from="600,80" to="780,15" control1="750,100" position="fixed" >}}
```

Use this for arrows that point to corners of the page or overlay content regardless of scroll position.

### Absolute (`position="absolute"`)
Positioned relative to the nearest `position: relative` ancestor.

```markdown
::: {style="position: relative; height: 200px;"}
Content here...
{{< arrow from="50,50" to="300,150" control1="175,20" position="absolute" >}}
:::
```

Use this for arrows within a specific container or diagram area.

## Styling Examples

```markdown
<!-- Red arrow -->
{{< arrow from="50,50" to="250,50" control1="150,120" color="red" >}}

<!-- Thick blue arrow -->
{{< arrow from="50,50" to="250,80" control1="150,150" color="blue" width="4" >}}

<!-- Large arrowhead -->
{{< arrow from="50,50" to="250,50" control1="150,120" color="green" size="15" >}}

<!-- CSS color names, hex, rgb all work -->
{{< arrow from="50,50" to="250,50" color="hotpink" >}}
{{< arrow from="50,50" to="250,50" color="#ff6600" >}}
{{< arrow from="50,50" to="250,50" color="rgb(100,150,200)" >}}
```

## Format Support

| Format | Support |
|--------|---------|
| HTML | Full support (inline SVG) |
| PDF | Basic support (SVG embedding) |
| Other | Text fallback (`->`) |

## How It Works

The extension generates inline SVG with:

1. **Bezier path**: Uses SVG `<path>` with `M` (move), `Q` (quadratic), `C` (cubic), or `L` (line) commands
2. **Arrowhead marker**: SVG `<marker>` element with `orient="auto-start-reverse"` for automatic rotation
3. **Auto-sizing**: Calculates bounding box from all points plus padding
4. **Coordinate adjustment**: Translates user coordinates to SVG viewBox coordinates

### Generated SVG Structure

```svg
<svg width="..." height="..." viewBox="0 0 ... ...">
  <defs>
    <marker id="arrow-XXXXX" ...>
      <path d="M 0 0 L 10 5 L 0 10 z" fill="black"/>
    </marker>
  </defs>
  <path d="M ... Q/C/L ..." stroke="black" marker-end="url(#arrow-XXXXX)"/>
</svg>
```

When positioned (`fixed` or `absolute`), the SVG is wrapped in:

```html
<div style="position: fixed|absolute; left: Xpx; top: Ypx; pointer-events: none; z-index: 9999;">
  <!-- SVG here -->
</div>
```

## File Structure

```
_extensions/arrow/
├── _extension.yml    # Extension metadata
└── arrow.lua         # Shortcode implementation
```

## Related Extensions

### quarto-leader-line

If you need to **connect DOM elements by selector** (e.g., draw an arrow from `#box1` to `#box2`), check out [quarto-leader-line](https://github.com/ofkoru/quarto-leader-line).

| Feature | quarto-arrow | quarto-leader-line |
|---------|--------------|-------------------|
| Targeting | Coordinates | CSS selectors |
| Format support | HTML, PDF, Typst (planned) | Reveal.js only |
| Dependencies | None (pure SVG) | leader-line.js |
| Dynamic updates | Static | Follows DOM elements |
| Use case | Diagrams, documents | Presentations |

**Use quarto-arrow when:**
- You need multi-format output (HTML + PDF)
- You want precise control over curve shape
- You're creating diagrams with known coordinates

**Use quarto-leader-line when:**
- You're building Reveal.js presentations
- You need arrows that connect to specific elements
- You want lines that update when elements move

## Future Enhancements

See [ROADMAP.md](ROADMAP.md) for planned features including:
- Additional arrowhead styles
- Dashed/dotted line styles
- Text labels along the arrow
- Animation support
- Typst format support
