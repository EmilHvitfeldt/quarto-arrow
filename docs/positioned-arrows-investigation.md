# Positioned Arrows Investigation

## Problem

Arrows using percentage-based coordinates with `position="absolute"` are not visible on the page.

## Example That Fails

```markdown
{{< arrow from="75%,100" to="98%,20" control1="92%,120" color="hotpink" width="3" position="absolute" >}}
```

## What We Learned

### The arrows ARE rendering

Debug output confirmed:
- Container elements exist and contain SVG markup
- `innerHTML length: 667` (non-empty)
- `has SVG: true`

### The arrows are positioned off-screen

```
SVG 0: visible=true, pos=(1251, 0), size=430x140
```

But viewport is only `innerWidth: 1144px`, so the arrow at x=1251 is off-screen to the right.

### Document dimensions at render time

```
scrollWidth: 1680
scrollHeight: 2493
innerWidth: 1144
innerHeight: 1019
```

The `scrollWidth` (1680) is significantly larger than `innerWidth` (1144).

### Root cause

The original code calculates percentage coordinates using `scrollWidth`/`scrollHeight`:

```javascript
if (unit === '%') {
  if (axis === 'x') {
    return (val / 100) * (config.position === 'fixed' ? window.innerWidth : document.documentElement.scrollWidth);
  } else {
    return (val / 100) * (config.position === 'fixed' ? window.innerHeight : document.documentElement.scrollHeight);
  }
}
```

For `position="absolute"`:
- 75% of scrollWidth (1680) = 1260px
- This is outside the visible viewport (1144px)

### Attempted fix

Changed to always use `innerWidth`/`innerHeight`:

```javascript
if (unit === '%') {
  if (axis === 'x') {
    return (val / 100) * window.innerWidth;
  } else {
    return (val / 100) * window.innerHeight;
  }
}
```

**Result:** Still not working. Need further investigation.

## Questions to Resolve

1. **What should percentage coordinates be relative to?**
   - Viewport (`innerWidth`/`innerHeight`)?
   - Document (`scrollWidth`/`scrollHeight`)?
   - A specific container element?

2. **Why is scrollWidth so much larger than innerWidth?**
   - Could the absolutely positioned arrows themselves be extending the document?
   - Is Quarto/Bootstrap adding extra width?

3. **Is `position: absolute` the right approach?**
   - Absolute positioning is relative to the nearest positioned ancestor
   - If no positioned ancestor, it's relative to the initial containing block
   - Maybe we need `position: fixed` for viewport-relative arrows?

4. **Should we provide different positioning modes?**
   - `position="viewport"` - relative to viewport (use fixed + innerWidth)
   - `position="document"` - relative to document (use absolute + scrollWidth)
   - `position="container"` - relative to a parent element

## Code Flow

1. `parse_point()` parses `"75%,100"` into `{x: {value: 75, unit: "%"}, y: {value: 100, unit: "px"}}`
2. `has_dynamic_coordinates()` returns `true` (has % unit)
3. `render_html_dynamic()` generates JavaScript that:
   - Embeds the config with parsed coordinates
   - Defines `resolveCoord()` to convert units to pixels at runtime
   - Calls `buildArrow()` on DOMContentLoaded and resize
4. `buildArrow()`:
   - Resolves all coordinates to pixels
   - Calculates bounding box
   - Generates SVG path
   - Inserts into container with absolute/fixed positioning

## Debug Code

To inspect arrow state in browser console:

```javascript
document.querySelectorAll('[id$="-container"]').forEach(el => {
  console.log('Container:', el.id);
  console.log('  innerHTML length:', el.innerHTML.length);
  console.log('  has SVG:', el.innerHTML.includes('<svg'));
});

console.log('scrollWidth:', document.documentElement.scrollWidth);
console.log('scrollHeight:', document.documentElement.scrollHeight);
console.log('innerWidth:', window.innerWidth);
console.log('innerHeight:', window.innerHeight);

document.querySelectorAll('svg').forEach((svg, i) => {
  const rect = svg.getBoundingClientRect();
  console.log(`SVG ${i}: visible=${rect.width > 0}, pos=(${rect.left.toFixed(0)}, ${rect.top.toFixed(0)}), size=${rect.width.toFixed(0)}x${rect.height.toFixed(0)}`);
});
```

## Files Involved

- `_extensions/arrow/arrow.lua` - main shortcode, contains `render_html_dynamic()`
- `_extensions/arrow/utils.lua` - pure utility functions (coordinate parsing, etc.)
- `tests/test_utils.lua` - unit tests for utils
