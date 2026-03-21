# quarto-arrows

A Quarto extension for drawing arrows with Bezier curves. Supports HTML, PDF, Typst, and RevealJS.

## Installation

```bash
quarto add emilhvitfeldt/quarto-arrows
```

## Usage

Add the filter to your document:

```yaml
---
title: My Document
format: html
filters:
  - arrows
---
```

Draw arrows with the shortcode:

```markdown
{{< arrow from="50,50" to="250,50" >}}
{{< arrow from="50,50" to="250,50" curve="0.5" color="blue" >}}
{{< arrow from="50,50" to="250,50" head="stealth" label="Click here" >}}
```

## Features

- **Curves**: Straight lines, quadratic/cubic Bezier, or simple `curve` parameter
- **Waypoints**: Complex paths through multiple points
- **Arrowheads**: 8 styles (arrow, stealth, diamond, circle, square, bar, barbed, none)
- **Line styles**: Single, dotted, double, triple
- **Labels**: Text labels with position control
- **Styling**: Colors, widths, opacity, dash patterns
- **Accessibility**: aria-label, alt text, title tooltips
- **RevealJS**: Draw animations with fragments

## Format Support

| Format | Status |
|--------|--------|
| HTML | Full support |
| PDF | Full support (TikZ) |
| Typst | Full support (CeTZ) |
| RevealJS | Full support + animations |

## Quick Examples

```markdown
<!-- Simple arrow -->
{{< arrow from="50,50" to="250,50" >}}

<!-- Curved arrow -->
{{< arrow from="50,50" to="250,50" curve="0.5" bend="left" >}}

<!-- Styled arrow -->
{{< arrow from="50,50" to="250,50" color="red" head="stealth" width="3" >}}

<!-- Arrow with label -->
{{< arrow from="50,50" to="250,50" curve="0.5" label="Step 1" >}}

<!-- RevealJS fragment animation -->
{{< arrow from="50,50" to="250,50" fragment="true" >}}
```

## Documentation

Full documentation with interactive examples: **[quarto-arrows website](https://emilhvitfeldt.github.io/quarto-arrows/)**

## License

MIT
