local M = {}

-- Load colors from nightfox palette if available
-- Returns the palette or nil if not loaded yet
local function load_nightfox_palette()
    local ok, palette_loader = pcall(require, "nightfox.palette")
    if not ok then return nil end

    local palette = palette_loader.load("nightfox")
    return palette
end

-- Get color value from nightfox Shade object or string
local function get_color(value)
    if type(value) == "table" and value.base then
        return value.base -- Shade object
    end
    return value -- Regular string color
end

-- Initialize colors from nightfox palette with fallbacks
function M.get_colors()
    local palette = load_nightfox_palette()

    if palette then
        return {
            -- Primary colors from nightfox
            black = get_color(palette.black),
            orange = get_color(palette.orange),
            green = get_color(palette.green),
            -- Foreground/background shades (ensure all are processed)
            fg0 = get_color(palette.fg0),
            fg1 = get_color(palette.fg1),
            fg2 = get_color(palette.fg2),
            fg3 = get_color(palette.fg3),
            bg0 = get_color(palette.bg0),
            bg1 = get_color(palette.bg1),
            bg2 = get_color(palette.bg2),
            bg3 = get_color(palette.bg3),
        }
    else
        -- Fallback colors matching nightfox palette
        return {
            black = "#393b44",
            orange = "#f4a261",
            green = "#81b29a",
            fg0 = "#d6d6d7",
            fg1 = "#cdcecf",
            fg2 = "#aeafb0",
            fg3 = "#71839b",
            bg0 = "#131a24",
            bg1 = "#192330",
            bg2 = "#212e3f",
            bg3 = "#29394f",
        }
    end
end

return M
