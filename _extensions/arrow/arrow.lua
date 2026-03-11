-- Arrow shortcode: draws curved SVG arrows with Bezier curves
-- Usage: {{< arrow from="x1,y1" to="x2,y2" control1="cx1,cy1" control2="cx2,cy2" >}}

--------------------------------------------------------------------------------
-- Utility Functions
--------------------------------------------------------------------------------

local function get_kwarg(kwargs, key, default)
  local val = kwargs[key] and pandoc.utils.stringify(kwargs[key]) or nil
  if val and val ~= "" then
    -- Strip surrounding quotes if present
    val = val:match('^"(.*)"$') or val:match("^'(.*)'$") or val
    return val
  end
  return default
end

local function get_kwarg_number(kwargs, key, default)
  local val = get_kwarg(kwargs, key, nil)
  return tonumber(val) or default
end

local function get_kwarg_bool(kwargs, key, default)
  local val = get_kwarg(kwargs, key, nil)
  if val == nil then return default end
  return val == "true"
end

local function parse_point(str)
  if not str or str == "" then return nil end
  local x, y = str:match("([^,]+),([^,]+)")
  if not x or not y then return nil end
  local nx, ny = tonumber(x), tonumber(y)
  if not nx or not ny then return nil end
  return {x = nx, y = ny}
end

local function generate_id(prefix)
  return (prefix or "arrow") .. "-" .. tostring(math.random(100000, 999999))
end

local function arr_min(arr)
  local m = arr[1]
  for i = 2, #arr do
    if arr[i] < m then m = arr[i] end
  end
  return m
end

local function arr_max(arr)
  local m = arr[1]
  for i = 2, #arr do
    if arr[i] > m then m = arr[i] end
  end
  return m
end

--------------------------------------------------------------------------------
-- Option Parsing
--------------------------------------------------------------------------------

local function parse_options(kwargs)
  local opts = {}

  -- Points
  opts.from = parse_point(get_kwarg(kwargs, "from", ""))
  opts.to = parse_point(get_kwarg(kwargs, "to", ""))
  opts.control1 = parse_point(get_kwarg(kwargs, "control1", ""))
  opts.control2 = parse_point(get_kwarg(kwargs, "control2", ""))

  -- Curve shortcuts (alternative to manual control points)
  opts.curve = get_kwarg_number(kwargs, "curve", nil)  -- 0-1 curviness
  opts.bend = get_kwarg(kwargs, "bend", nil)  -- "left", "right", or angle in degrees

  -- Styling
  opts.color = get_kwarg(kwargs, "color", "black")
  opts.width = get_kwarg_number(kwargs, "width", 2)
  opts.size = get_kwarg_number(kwargs, "size", 10)
  opts.head_size = get_kwarg_number(kwargs, "head-size", nil)  -- Independent head sizing

  -- Line style
  opts.dash = get_kwarg(kwargs, "dash", nil)
  opts.line = get_kwarg(kwargs, "line", "single")  -- single, dot, double, triple
  opts.opacity = get_kwarg_number(kwargs, "opacity", 1)

  -- Arrowhead options
  opts.head = get_kwarg(kwargs, "head", "arrow")
  opts.head_start = get_kwarg_bool(kwargs, "head-start", false)
  opts.head_end = get_kwarg_bool(kwargs, "head-end", true)
  opts.head_fill = get_kwarg_bool(kwargs, "head-fill", true)

  -- Positioning
  opts.position = get_kwarg(kwargs, "position", nil)

  -- Label options
  opts.label = get_kwarg(kwargs, "label", nil)
  opts.label_position = get_kwarg(kwargs, "label-position", "middle")  -- start, middle, end
  opts.label_offset = get_kwarg_number(kwargs, "label-offset", 10)

  -- Accessibility (future)
  opts.aria_label = get_kwarg(kwargs, "aria-label", nil)
  opts.alt = get_kwarg(kwargs, "alt", nil)
  opts.css_class = get_kwarg(kwargs, "class", nil)

  return opts
end

--------------------------------------------------------------------------------
-- Auto Control Point Calculation
--------------------------------------------------------------------------------

local function calculate_auto_control(opts)
  -- Skip if control points are already specified or no curve parameter
  if opts.control1 or not opts.curve then
    return
  end

  local from = opts.from
  local to = opts.to
  if not from or not to then return end

  -- Calculate midpoint
  local mid_x = (from.x + to.x) / 2
  local mid_y = (from.y + to.y) / 2

  -- Calculate line length and angle
  local dx = to.x - from.x
  local dy = to.y - from.y
  local length = math.sqrt(dx * dx + dy * dy)
  local line_angle = math.atan(dy, dx)

  -- Determine bend direction
  local bend_angle
  if opts.bend == "left" then
    bend_angle = line_angle - math.pi / 2  -- perpendicular left
  elseif opts.bend == "right" then
    bend_angle = line_angle + math.pi / 2  -- perpendicular right
  elseif opts.bend then
    -- Numeric angle in degrees
    local degrees = tonumber(opts.bend)
    if degrees then
      bend_angle = math.rad(degrees)
    else
      bend_angle = line_angle - math.pi / 2  -- default to left
    end
  else
    bend_angle = line_angle - math.pi / 2  -- default to left (above for horizontal)
  end

  -- Calculate offset distance based on curve parameter and line length
  local curve_amount = math.max(0, math.min(1, opts.curve))  -- clamp 0-1
  local offset = curve_amount * length * 0.5

  -- Calculate control point
  opts.control1 = {
    x = mid_x + offset * math.cos(bend_angle),
    y = mid_y + offset * math.sin(bend_angle)
  }
end

--------------------------------------------------------------------------------
-- Bounding Box Calculation
--------------------------------------------------------------------------------

local function calculate_bounds(opts)
  local head_size = opts.head_size or opts.size
  local padding = head_size + 10
  local all_x = {opts.from.x, opts.to.x}
  local all_y = {opts.from.y, opts.to.y}

  if opts.control1 then
    table.insert(all_x, opts.control1.x)
    table.insert(all_y, opts.control1.y)
  end
  if opts.control2 then
    table.insert(all_x, opts.control2.x)
    table.insert(all_y, opts.control2.y)
  end

  return {
    min_x = arr_min(all_x) - padding,
    max_x = arr_max(all_x) + padding,
    min_y = arr_min(all_y) - padding,
    max_y = arr_max(all_y) + padding
  }
end

local function adjust_point(point, bounds)
  if not point then return nil end
  return {
    x = point.x - bounds.min_x,
    y = point.y - bounds.min_y
  }
end

--------------------------------------------------------------------------------
-- SVG Path Generation
--------------------------------------------------------------------------------

local function build_path(adj_from, adj_to, adj_c1, adj_c2)
  if adj_c1 and adj_c2 then
    -- Cubic Bezier
    return string.format("M %.1f,%.1f C %.1f,%.1f %.1f,%.1f %.1f,%.1f",
      adj_from.x, adj_from.y,
      adj_c1.x, adj_c1.y,
      adj_c2.x, adj_c2.y,
      adj_to.x, adj_to.y)
  elseif adj_c1 then
    -- Quadratic Bezier
    return string.format("M %.1f,%.1f Q %.1f,%.1f %.1f,%.1f",
      adj_from.x, adj_from.y,
      adj_c1.x, adj_c1.y,
      adj_to.x, adj_to.y)
  else
    -- Straight line
    return string.format("M %.1f,%.1f L %.1f,%.1f",
      adj_from.x, adj_from.y,
      adj_to.x, adj_to.y)
  end
end

--------------------------------------------------------------------------------
-- Label Position Calculation
--------------------------------------------------------------------------------

-- Linear interpolation
local function lerp(a, b, t)
  return a + (b - a) * t
end

-- Calculate point on quadratic Bezier at t (0-1)
local function quadratic_bezier_point(p0, p1, p2, t)
  local u = 1 - t
  return {
    x = u*u*p0.x + 2*u*t*p1.x + t*t*p2.x,
    y = u*u*p0.y + 2*u*t*p1.y + t*t*p2.y
  }
end

-- Calculate point on cubic Bezier at t (0-1)
local function cubic_bezier_point(p0, p1, p2, p3, t)
  local u = 1 - t
  return {
    x = u*u*u*p0.x + 3*u*u*t*p1.x + 3*u*t*t*p2.x + t*t*t*p3.x,
    y = u*u*u*p0.y + 3*u*u*t*p1.y + 3*u*t*t*p2.y + t*t*t*p3.y
  }
end

-- Calculate tangent angle at point on path
local function calculate_tangent_angle(adj_from, adj_to, adj_c1, adj_c2, t)
  local dx, dy
  local epsilon = 0.001
  local t1 = math.max(0, t - epsilon)
  local t2 = math.min(1, t + epsilon)

  if adj_c1 and adj_c2 then
    local p1 = cubic_bezier_point(adj_from, adj_c1, adj_c2, adj_to, t1)
    local p2 = cubic_bezier_point(adj_from, adj_c1, adj_c2, adj_to, t2)
    dx = p2.x - p1.x
    dy = p2.y - p1.y
  elseif adj_c1 then
    local p1 = quadratic_bezier_point(adj_from, adj_c1, adj_to, t1)
    local p2 = quadratic_bezier_point(adj_from, adj_c1, adj_to, t2)
    dx = p2.x - p1.x
    dy = p2.y - p1.y
  else
    dx = adj_to.x - adj_from.x
    dy = adj_to.y - adj_from.y
  end

  return math.atan(dy, dx)
end

-- Get label position and perpendicular offset
local function get_label_position(adj_from, adj_to, adj_c1, adj_c2, position, offset)
  local t
  if position == "start" then
    t = 0.15
  elseif position == "end" then
    t = 0.85
  else
    t = 0.5  -- middle (default)
  end

  local point
  if adj_c1 and adj_c2 then
    point = cubic_bezier_point(adj_from, adj_c1, adj_c2, adj_to, t)
  elseif adj_c1 then
    point = quadratic_bezier_point(adj_from, adj_c1, adj_to, t)
  else
    point = {
      x = lerp(adj_from.x, adj_to.x, t),
      y = lerp(adj_from.y, adj_to.y, t)
    }
  end

  -- Calculate perpendicular offset (above the line)
  local angle = calculate_tangent_angle(adj_from, adj_to, adj_c1, adj_c2, t)
  local perp_angle = angle - math.pi / 2  -- perpendicular (above)

  return {
    x = point.x + offset * math.cos(perp_angle),
    y = point.y + offset * math.sin(perp_angle),
    angle = math.deg(angle)
  }
end

--------------------------------------------------------------------------------
-- SVG Marker (Arrowhead) Generation
--------------------------------------------------------------------------------

-- Arrowhead style definitions
-- Each returns: {path = "...", refX = n, refY = n, width = n, height = n, is_stroke = bool}
local MARKER_STYLES = {
  arrow = function(size)
    -- Default filled triangle pointing right
    return {
      path = string.format("M 0 0 L %s %s L 0 %s z", size, size/2, size),
      refX = 0,  -- Base of arrowhead, so stroke ends here
      refY = size/2,
      width = size,
      height = size,
      is_stroke = false
    }
  end,

  stealth = function(size)
    -- Pointed, angular military-style arrow
    local w = size * 1.2
    local h = size
    return {
      path = string.format("M 0 0 L %s %s L 0 %s L %s %s z", w, h/2, h, w*0.3, h/2),
      refX = w*0.3,  -- Inner notch point, so stroke ends inside
      refY = h/2,
      width = w,
      height = h,
      is_stroke = false
    }
  end,

  diamond = function(size)
    -- Diamond/rhombus shape
    local w = size
    local h = size
    return {
      path = string.format("M 0 %s L %s 0 L %s %s L %s %s z", h/2, w/2, w, h/2, w/2, h),
      refX = w/2,  -- Center of diamond, so stroke ends at middle
      refY = h/2,
      width = w,
      height = h,
      is_stroke = false
    }
  end,

  circle = function(size)
    -- Round endpoint (circle)
    local r = size / 2
    return {
      path = string.format("M %s %s m -%s 0 a %s %s 0 1 0 %s 0 a %s %s 0 1 0 -%s 0",
        r, r, r, r, r, r*2, r, r, r*2),
      refX = r,  -- Center of circle, so stroke ends at middle
      refY = r,
      width = size,
      height = size,
      is_stroke = false
    }
  end,


  square = function(size)
    -- Square endpoint
    return {
      path = string.format("M 0 0 L %s 0 L %s %s L 0 %s z", size, size, size, size),
      refX = size/2,  -- Center of square, so stroke ends at middle
      refY = size/2,
      width = size,
      height = size,
      is_stroke = false
    }
  end,

  bar = function(size)
    -- Flat perpendicular line (stop)
    local w = size / 3
    local h = size
    return {
      path = string.format("M 0 0 L %s 0 L %s %s L 0 %s z", w, w, h, h),
      refX = w/2,  -- Center of bar, so stroke ends at middle
      refY = h/2,
      width = w,
      height = h,
      is_stroke = false
    }
  end,

  barbed = function(size)
    -- Hook-like, fishing arrow style (open, no fill)
    local w = size
    local h = size
    return {
      path = string.format("M 0 0 L %s %s L 0 %s", w, h/2, h),
      refX = w,  -- Tip of barbed arrow (stroke-based, so it connects at tip)
      refY = h/2,
      width = w,
      height = h,
      is_stroke = true
    }
  end,
}

local function build_marker(id, opts)
  local size = opts.head_size or opts.size  -- Use head-size if provided, otherwise size
  local color = opts.color
  local style = opts.head
  local fill = opts.head_fill

  -- Handle aliases
  if style == "dot" then style = "circle" end
  if style == "stop" then style = "bar" end

  -- Get style generator, default to arrow
  local style_fn = MARKER_STYLES[style] or MARKER_STYLES.arrow
  local marker = style_fn(size)

  -- Determine fill and stroke based on style and head-fill option
  local path_attrs
  if marker.is_stroke or not fill then
    -- Stroke-based marker (outline)
    path_attrs = string.format('fill="none" stroke="%s" stroke-width="1.5"', color)
  else
    -- Fill-based marker (solid)
    path_attrs = string.format('fill="%s"', color)
  end

  return string.format(
    '<marker id="%s" markerWidth="%s" markerHeight="%s" refX="%s" refY="%s" orient="auto-start-reverse" markerUnits="strokeWidth">' ..
    '<path d="%s" %s/>' ..
    '</marker>',
    id, marker.width, marker.height, marker.refX, marker.refY,
    marker.path, path_attrs)
end

--------------------------------------------------------------------------------
-- SVG Stroke Attributes
--------------------------------------------------------------------------------

local function build_stroke_attrs(opts, override_width, override_color)
  local width = override_width or opts.width
  local color = override_color or opts.color

  local attrs = {
    string.format('stroke="%s"', color),
    string.format('stroke-width="%s"', width),
    'fill="none"'
  }

  -- Dash pattern
  if opts.dash then
    if opts.dash == "true" then
      table.insert(attrs, 'stroke-dasharray="5,5"')
    else
      table.insert(attrs, string.format('stroke-dasharray="%s"', opts.dash))
    end
  end

  -- Dot pattern (small dots)
  if opts.line == "dot" and not opts.dash then
    local dot_size = math.max(1, width * 0.5)
    local gap_size = width * 2
    table.insert(attrs, string.format('stroke-dasharray="%.1f,%.1f"', dot_size, gap_size))
    table.insert(attrs, 'stroke-linecap="round"')
  end

  -- Opacity
  if opts.opacity < 1 then
    table.insert(attrs, string.format('stroke-opacity="%.2f"', opts.opacity))
  end

  return table.concat(attrs, " ")
end

--------------------------------------------------------------------------------
-- SVG Assembly
--------------------------------------------------------------------------------

local function build_svg(opts, bounds, path_d, marker_id, adj_from, adj_to, adj_c1, adj_c2)
  local svg_width = bounds.max_x - bounds.min_x
  local svg_height = bounds.max_y - bounds.min_y

  -- Build marker(s) - skip if head="none"
  local markers = {}
  local has_markers = (opts.head_end or opts.head_start) and opts.head ~= "none"
  if has_markers then
    table.insert(markers, build_marker(marker_id, opts))
  end

  -- Build defs section
  local defs = ""
  if #markers > 0 then
    defs = "<defs>" .. table.concat(markers, "") .. "</defs>"
  end

  -- Build marker references
  local marker_attrs = {}
  if has_markers then
    if opts.head_end then
      table.insert(marker_attrs, string.format('marker-end="url(#%s)"', marker_id))
    end
    if opts.head_start then
      table.insert(marker_attrs, string.format('marker-start="url(#%s)"', marker_id))
    end
  end

  -- Build path elements based on line style
  local paths = {}
  local stroke_attrs = build_stroke_attrs(opts)

  if opts.line == "double" then
    -- Double line: thick outer stroke + thin white gap in middle
    local outer_width = opts.width * 3
    local gap_width = opts.width
    local outer_attrs = build_stroke_attrs(opts, outer_width, opts.color)
    local gap_attrs = build_stroke_attrs(opts, gap_width, "white")
    -- Outer stroke (no markers)
    table.insert(paths, string.format('<path d="%s" %s/>', path_d, outer_attrs))
    -- Gap stroke (no markers)
    table.insert(paths, string.format('<path d="%s" %s/>', path_d, gap_attrs))
  elseif opts.line == "triple" then
    -- Triple line: thick outer + two gaps
    local outer_width = opts.width * 5
    local gap_width = opts.width
    local outer_attrs = build_stroke_attrs(opts, outer_width, opts.color)
    local gap_attrs = build_stroke_attrs(opts, gap_width, "white")
    -- Outer stroke
    table.insert(paths, string.format('<path d="%s" %s/>', path_d, outer_attrs))
    -- Two gap strokes at different positions (simulated with single wider gap)
    local inner_gap_width = opts.width * 3
    local inner_gap_attrs = build_stroke_attrs(opts, inner_gap_width, "white")
    table.insert(paths, string.format('<path d="%s" %s/>', path_d, inner_gap_attrs))
    -- Center line
    local center_attrs = build_stroke_attrs(opts, gap_width, opts.color)
    table.insert(paths, string.format('<path d="%s" %s/>', path_d, center_attrs))
  end

  -- Accessibility attributes
  local a11y_attrs = {}
  if opts.aria_label then
    table.insert(a11y_attrs, string.format('aria-label="%s"', opts.aria_label))
    table.insert(a11y_attrs, 'role="img"')
  end

  -- CSS class
  local class_attr = ""
  if opts.css_class then
    class_attr = string.format(' class="%s"', opts.css_class)
  end

  -- Build path content
  local path_content
  if #paths > 0 then
    -- Multiple paths for double/triple lines
    -- Add markers only to the final (topmost) path
    local final_path = paths[#paths]
    paths[#paths] = final_path:gsub('/>$', ' ' .. table.concat(marker_attrs, " ") .. '/>')
    path_content = table.concat(paths, "")
  else
    -- Single path (default, dot, etc.)
    path_content = string.format('<path d="%s" %s %s/>',
      path_d, stroke_attrs, table.concat(marker_attrs, " "))
  end

  -- Build label element
  local label_content = ""
  if opts.label and opts.label ~= "" then
    local label_pos = get_label_position(adj_from, adj_to, adj_c1, adj_c2, opts.label_position, opts.label_offset)
    -- Normalize angle to keep text readable (not upside down)
    local angle = label_pos.angle
    if angle > 90 or angle < -90 then
      angle = angle + 180
    end
    label_content = string.format(
      '<text x="%.1f" y="%.1f" text-anchor="middle" dominant-baseline="middle" fill="%s" font-size="12" font-family="sans-serif" transform="rotate(%.1f %.1f %.1f)">%s</text>',
      label_pos.x, label_pos.y, opts.color, angle, label_pos.x, label_pos.y, opts.label)
  end

  return string.format(
    '<svg width="%.1f" height="%.1f" viewBox="0 0 %.1f %.1f" xmlns="http://www.w3.org/2000/svg" style="overflow: visible;"%s%s>%s%s%s</svg>',
    svg_width, svg_height, svg_width, svg_height,
    class_attr,
    #a11y_attrs > 0 and (" " .. table.concat(a11y_attrs, " ")) or "",
    defs,
    path_content,
    label_content)
end

--------------------------------------------------------------------------------
-- HTML Output
--------------------------------------------------------------------------------

local function render_html(svg, opts, bounds)
  local output
  local is_positioned = opts.position == "fixed" or opts.position == "absolute"

  if is_positioned then
    output = string.format(
      '<div style="position: %s; left: %.1fpx; top: %.1fpx; pointer-events: none; z-index: 9999;">%s</div>',
      opts.position, bounds.min_x, bounds.min_y, svg)
    return pandoc.RawBlock("html", output)
  else
    return pandoc.RawInline("html", svg)
  end
end

--------------------------------------------------------------------------------
-- Typst Output (placeholder for future implementation)
--------------------------------------------------------------------------------

local function render_typst(opts, bounds)
  -- TODO: Implement native Typst path generation
  -- For now, return a placeholder
  return pandoc.RawInline("typst", "#text(fill: gray)[(arrow)]")
end

--------------------------------------------------------------------------------
-- Main Shortcode Function
--------------------------------------------------------------------------------

function arrow(args, kwargs, meta, raw_args, context)
  -- Parse all options
  local opts = parse_options(kwargs)

  -- Validate required arguments
  if not opts.from or not opts.to then
    quarto.log.error("Arrow shortcode requires 'from' and 'to' coordinates")
    return pandoc.Str("[arrow: missing coordinates]")
  end

  -- Auto-calculate control points if curve/bend specified
  calculate_auto_control(opts)

  -- Calculate bounding box
  local bounds = calculate_bounds(opts)

  -- Adjust coordinates relative to viewBox
  local adj_from = adjust_point(opts.from, bounds)
  local adj_to = adjust_point(opts.to, bounds)
  local adj_c1 = adjust_point(opts.control1, bounds)
  local adj_c2 = adjust_point(opts.control2, bounds)

  -- Build SVG path
  local path_d = build_path(adj_from, adj_to, adj_c1, adj_c2)

  -- Generate unique marker ID
  local marker_id = generate_id("arrow")

  -- Build complete SVG
  local svg = build_svg(opts, bounds, path_d, marker_id, adj_from, adj_to, adj_c1, adj_c2)

  -- Return format-appropriate output
  if quarto.doc.isFormat("html:js") then
    return render_html(svg, opts, bounds)
  elseif quarto.doc.isFormat("typst") then
    return render_typst(opts, bounds)
  elseif quarto.doc.isFormat("pdf") then
    return pandoc.RawInline("html", svg)
  else
    return pandoc.Str("->")
  end
end
