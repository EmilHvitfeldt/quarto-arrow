#!/usr/bin/env lua
-- Unit tests for arrow utils
-- Run with: lua tests/test_utils.lua (from project root)

-- Add extension directory to path so we can require utils
package.path = package.path .. ";../_extensions/arrow/?.lua"
local utils = require("utils")

local tests_run = 0
local tests_passed = 0

local function test(name, fn)
  tests_run = tests_run + 1
  local ok, err = pcall(fn)
  if ok then
    tests_passed = tests_passed + 1
    print("  PASS: " .. name)
  else
    print("  FAIL: " .. name)
    print("        " .. tostring(err))
  end
end

local function assert_eq(actual, expected, msg)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s",
      msg or "assertion failed", tostring(expected), tostring(actual)))
  end
end

local function assert_nil(actual, msg)
  if actual ~= nil then
    error(string.format("%s: expected nil, got %s", msg or "assertion failed", tostring(actual)))
  end
end

local function assert_not_nil(actual, msg)
  if actual == nil then
    error(string.format("%s: expected non-nil value", msg or "assertion failed"))
  end
end

--------------------------------------------------------------------------------
print("\n=== parse_coordinate ===")
--------------------------------------------------------------------------------

test("parses plain integer as pixels", function()
  local c = utils.parse_coordinate("100")
  assert_eq(c.value, 100, "value")
  assert_eq(c.unit, "px", "unit")
end)

test("parses decimal as pixels", function()
  local c = utils.parse_coordinate("100.5")
  assert_eq(c.value, 100.5, "value")
  assert_eq(c.unit, "px", "unit")
end)

test("parses percentage", function()
  local c = utils.parse_coordinate("50%")
  assert_eq(c.value, 50, "value")
  assert_eq(c.unit, "%", "unit")
end)

test("parses decimal percentage", function()
  local c = utils.parse_coordinate("33.33%")
  assert_eq(c.value, 33.33, "value")
  assert_eq(c.unit, "%", "unit")
end)

test("parses viewport width", function()
  local c = utils.parse_coordinate("10vw")
  assert_eq(c.value, 10, "value")
  assert_eq(c.unit, "vw", "unit")
end)

test("parses viewport height", function()
  local c = utils.parse_coordinate("20vh")
  assert_eq(c.value, 20, "value")
  assert_eq(c.unit, "vh", "unit")
end)

test("trims whitespace", function()
  local c = utils.parse_coordinate("  100  ")
  assert_eq(c.value, 100, "value")
end)

test("returns nil for empty string", function()
  local c = utils.parse_coordinate("")
  assert_nil(c, "empty string")
end)

test("returns nil for nil input", function()
  local c = utils.parse_coordinate(nil)
  assert_nil(c, "nil input")
end)

test("returns nil for invalid input", function()
  local c = utils.parse_coordinate("abc")
  assert_nil(c, "invalid input")
end)

test("returns nil for partial unit", function()
  local c = utils.parse_coordinate("100v")
  assert_nil(c, "partial unit")
end)

--------------------------------------------------------------------------------
print("\n=== parse_point ===")
--------------------------------------------------------------------------------

test("parses simple pixel coordinates", function()
  local p = utils.parse_point("100,200")
  assert_eq(p.x.value, 100, "x value")
  assert_eq(p.x.unit, "px", "x unit")
  assert_eq(p.y.value, 200, "y value")
  assert_eq(p.y.unit, "px", "y unit")
end)

test("parses percentage coordinates", function()
  local p = utils.parse_point("50%,75%")
  assert_eq(p.x.value, 50, "x value")
  assert_eq(p.x.unit, "%", "x unit")
  assert_eq(p.y.value, 75, "y value")
  assert_eq(p.y.unit, "%", "y unit")
end)

test("parses mixed units", function()
  local p = utils.parse_point("50%,100")
  assert_eq(p.x.unit, "%", "x unit")
  assert_eq(p.y.unit, "px", "y unit")
end)

test("parses viewport units", function()
  local p = utils.parse_point("10vw,20vh")
  assert_eq(p.x.unit, "vw", "x unit")
  assert_eq(p.y.unit, "vh", "y unit")
end)

test("returns nil for empty string", function()
  local p = utils.parse_point("")
  assert_nil(p, "empty string")
end)

test("returns nil for nil input", function()
  local p = utils.parse_point(nil)
  assert_nil(p, "nil input")
end)

test("returns nil for missing comma", function()
  local p = utils.parse_point("100 200")
  assert_nil(p, "missing comma")
end)

test("returns nil for single value", function()
  local p = utils.parse_point("100")
  assert_nil(p, "single value")
end)

test("returns nil if x is invalid", function()
  local p = utils.parse_point("abc,100")
  assert_nil(p, "invalid x")
end)

test("returns nil if y is invalid", function()
  local p = utils.parse_point("100,abc")
  assert_nil(p, "invalid y")
end)

--------------------------------------------------------------------------------
print("\n=== point_has_dynamic_units ===")
--------------------------------------------------------------------------------

test("returns false for nil point", function()
  assert_eq(utils.point_has_dynamic_units(nil), false, "nil point")
end)

test("returns false for pixel-only point", function()
  local p = utils.parse_point("100,200")
  assert_eq(utils.point_has_dynamic_units(p), false, "pixel point")
end)

test("returns true for percentage x", function()
  local p = utils.parse_point("50%,200")
  assert_eq(utils.point_has_dynamic_units(p), true, "percentage x")
end)

test("returns true for percentage y", function()
  local p = utils.parse_point("100,50%")
  assert_eq(utils.point_has_dynamic_units(p), true, "percentage y")
end)

test("returns true for viewport units", function()
  local p = utils.parse_point("10vw,20vh")
  assert_eq(utils.point_has_dynamic_units(p), true, "viewport units")
end)

--------------------------------------------------------------------------------
print("\n=== has_dynamic_coordinates ===")
--------------------------------------------------------------------------------

test("returns false when all points are pixels", function()
  local opts = {
    from = utils.parse_point("0,0"),
    to = utils.parse_point("100,100"),
    control1 = utils.parse_point("50,0"),
    control2 = nil
  }
  assert_eq(utils.has_dynamic_coordinates(opts), false, "all pixels")
end)

test("returns true when from has dynamic units", function()
  local opts = {
    from = utils.parse_point("50%,0"),
    to = utils.parse_point("100,100"),
    control1 = nil,
    control2 = nil
  }
  assert_eq(utils.has_dynamic_coordinates(opts), true, "dynamic from")
end)

test("returns true when to has dynamic units", function()
  local opts = {
    from = utils.parse_point("0,0"),
    to = utils.parse_point("100%,100%"),
    control1 = nil,
    control2 = nil
  }
  assert_eq(utils.has_dynamic_coordinates(opts), true, "dynamic to")
end)

test("returns true when control1 has dynamic units", function()
  local opts = {
    from = utils.parse_point("0,0"),
    to = utils.parse_point("100,100"),
    control1 = utils.parse_point("50vw,50vh"),
    control2 = nil
  }
  assert_eq(utils.has_dynamic_coordinates(opts), true, "dynamic control1")
end)

--------------------------------------------------------------------------------
print("\n=== point_to_pixels ===")
--------------------------------------------------------------------------------

test("returns nil for nil input", function()
  assert_nil(utils.point_to_pixels(nil), "nil input")
end)

test("extracts values from point", function()
  local p = utils.parse_point("100,200")
  local px = utils.point_to_pixels(p)
  assert_eq(px.x, 100, "x value")
  assert_eq(px.y, 200, "y value")
end)

--------------------------------------------------------------------------------
print("\n=== arr_min / arr_max ===")
--------------------------------------------------------------------------------

test("arr_min finds minimum", function()
  assert_eq(utils.arr_min({5, 3, 8, 1, 9}), 1, "minimum")
end)

test("arr_min with single element", function()
  assert_eq(utils.arr_min({42}), 42, "single element")
end)

test("arr_min with negative numbers", function()
  assert_eq(utils.arr_min({-5, 3, -8, 1}), -8, "negative min")
end)

test("arr_max finds maximum", function()
  assert_eq(utils.arr_max({5, 3, 8, 1, 9}), 9, "maximum")
end)

test("arr_max with single element", function()
  assert_eq(utils.arr_max({42}), 42, "single element")
end)

test("arr_max with negative numbers", function()
  assert_eq(utils.arr_max({-5, 3, -8, 1}), 3, "negative max")
end)

--------------------------------------------------------------------------------
print("\n=== calculate_bounds ===")
--------------------------------------------------------------------------------

test("calculates bounds for straight line", function()
  local from = {x = 10, y = 20}
  local to = {x = 100, y = 80}
  local bounds = utils.calculate_bounds(from, to, nil, nil, 5)
  assert_eq(bounds.min_x, 5, "min_x")
  assert_eq(bounds.max_x, 105, "max_x")
  assert_eq(bounds.min_y, 15, "min_y")
  assert_eq(bounds.max_y, 85, "max_y")
end)

test("includes control point in bounds", function()
  local from = {x = 0, y = 0}
  local to = {x = 100, y = 100}
  local c1 = {x = 50, y = -50}  -- control point outside line
  local bounds = utils.calculate_bounds(from, to, c1, nil, 10)
  assert_eq(bounds.min_y, -60, "min_y includes control")
end)

test("includes both control points", function()
  local from = {x = 0, y = 0}
  local to = {x = 100, y = 100}
  local c1 = {x = -20, y = 50}
  local c2 = {x = 120, y = 50}
  local bounds = utils.calculate_bounds(from, to, c1, c2, 0)
  assert_eq(bounds.min_x, -20, "min_x from c1")
  assert_eq(bounds.max_x, 120, "max_x from c2")
end)

--------------------------------------------------------------------------------
print("\n=== adjust_point ===")
--------------------------------------------------------------------------------

test("returns nil for nil input", function()
  local bounds = {min_x = 10, min_y = 20}
  assert_nil(utils.adjust_point(nil, bounds), "nil input")
end)

test("adjusts point relative to bounds", function()
  local point = {x = 50, y = 80}
  local bounds = {min_x = 10, min_y = 20}
  local adj = utils.adjust_point(point, bounds)
  assert_eq(adj.x, 40, "adjusted x")
  assert_eq(adj.y, 60, "adjusted y")
end)

--------------------------------------------------------------------------------
print("\n=== build_path ===")
--------------------------------------------------------------------------------

test("builds straight line path", function()
  local path = utils.build_path({x=0, y=0}, {x=100, y=100}, nil, nil)
  assert_eq(path, "M 0.0,0.0 L 100.0,100.0", "straight line")
end)

test("builds quadratic bezier path", function()
  local path = utils.build_path({x=0, y=0}, {x=100, y=100}, {x=50, y=0}, nil)
  assert_eq(path, "M 0.0,0.0 Q 50.0,0.0 100.0,100.0", "quadratic bezier")
end)

test("builds cubic bezier path", function()
  local path = utils.build_path({x=0, y=0}, {x=100, y=100}, {x=25, y=0}, {x=75, y=100})
  assert_eq(path, "M 0.0,0.0 C 25.0,0.0 75.0,100.0 100.0,100.0", "cubic bezier")
end)

--------------------------------------------------------------------------------
print("\n=== build_stroke_attrs ===")
--------------------------------------------------------------------------------

test("builds basic stroke attributes", function()
  local opts = {color = "red", width = 2, opacity = 1}
  local attrs = utils.build_stroke_attrs(opts)
  assert(attrs:find('stroke="red"'), "has color")
  assert(attrs:find('stroke%-width="2"'), "has width")
  assert(attrs:find('fill="none"'), "has fill none")
end)

test("includes dash array when dash is true", function()
  local opts = {color = "black", width = 1, opacity = 1, dash = "true"}
  local attrs = utils.build_stroke_attrs(opts)
  assert(attrs:find('stroke%-dasharray="5,5"'), "has default dash")
end)

test("includes custom dash array", function()
  local opts = {color = "black", width = 1, opacity = 1, dash = "10,5,2,5"}
  local attrs = utils.build_stroke_attrs(opts)
  assert(attrs:find('stroke%-dasharray="10,5,2,5"'), "has custom dash")
end)

test("includes opacity when less than 1", function()
  local opts = {color = "black", width = 1, opacity = 0.5}
  local attrs = utils.build_stroke_attrs(opts)
  assert(attrs:find('stroke%-opacity="0.50"'), "has opacity")
end)

test("excludes opacity when equal to 1", function()
  local opts = {color = "black", width = 1, opacity = 1}
  local attrs = utils.build_stroke_attrs(opts)
  assert(not attrs:find('stroke%-opacity'), "no opacity attr")
end)

--------------------------------------------------------------------------------
print("\n=== get_kwarg ===")
--------------------------------------------------------------------------------

test("returns value when present", function()
  local kwargs = {color = "red"}
  assert_eq(utils.get_kwarg(kwargs, "color", "black"), "red", "present value")
end)

test("returns default when missing", function()
  local kwargs = {}
  assert_eq(utils.get_kwarg(kwargs, "color", "black"), "black", "default value")
end)

test("strips double quotes", function()
  local kwargs = {color = '"red"'}
  assert_eq(utils.get_kwarg(kwargs, "color", "black"), "red", "stripped quotes")
end)

test("strips single quotes", function()
  local kwargs = {color = "'red'"}
  assert_eq(utils.get_kwarg(kwargs, "color", "black"), "red", "stripped quotes")
end)

test("returns default for empty string", function()
  local kwargs = {color = ""}
  assert_eq(utils.get_kwarg(kwargs, "color", "black"), "black", "empty string")
end)

--------------------------------------------------------------------------------
print("\n=== get_kwarg_number ===")
--------------------------------------------------------------------------------

test("parses integer", function()
  local kwargs = {width = "5"}
  assert_eq(utils.get_kwarg_number(kwargs, "width", 2), 5, "integer")
end)

test("parses float", function()
  local kwargs = {opacity = "0.5"}
  assert_eq(utils.get_kwarg_number(kwargs, "opacity", 1), 0.5, "float")
end)

test("returns default for non-numeric", function()
  local kwargs = {width = "thick"}
  assert_eq(utils.get_kwarg_number(kwargs, "width", 2), 2, "non-numeric")
end)

test("returns default when missing", function()
  local kwargs = {}
  assert_eq(utils.get_kwarg_number(kwargs, "width", 2), 2, "missing")
end)

--------------------------------------------------------------------------------
print("\n=== get_kwarg_bool ===")
--------------------------------------------------------------------------------

test("parses true string", function()
  local kwargs = {enabled = "true"}
  assert_eq(utils.get_kwarg_bool(kwargs, "enabled", false), true, "true string")
end)

test("parses false string", function()
  local kwargs = {enabled = "false"}
  assert_eq(utils.get_kwarg_bool(kwargs, "enabled", true), false, "false string")
end)

test("returns default when missing", function()
  local kwargs = {}
  assert_eq(utils.get_kwarg_bool(kwargs, "enabled", true), true, "missing -> default true")
  assert_eq(utils.get_kwarg_bool(kwargs, "enabled", false), false, "missing -> default false")
end)

test("treats non-true as false", function()
  local kwargs = {enabled = "yes"}
  assert_eq(utils.get_kwarg_bool(kwargs, "enabled", true), false, "yes is not true")
end)

--------------------------------------------------------------------------------
-- Summary
--------------------------------------------------------------------------------

print("\n" .. string.rep("=", 50))
print(string.format("Results: %d/%d tests passed", tests_passed, tests_run))
if tests_passed == tests_run then
  print("All tests passed!")
  os.exit(0)
else
  print(string.format("%d tests failed", tests_run - tests_passed))
  os.exit(1)
end
