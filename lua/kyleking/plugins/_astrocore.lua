-- PLANNED: Investigate AstroCore for whickey, tabline, and resession
return {
  {
    "AstroNvim/astrocore",
    enabled = false, -- PLANNED: investigate
    dependencies = { "AstroNvim/astroui" },
    lazy = false,
    priority = 10000,
    ---@type AstroCoreOpts
    opts = {
      features = {
        max_file = { size = 1024 * 100, lines = 10000 }, -- set global limits for large files
        -- autopairs = true, -- enable autopairs at start
        -- cmp = true, -- enable completion at start
        highlighturl = true, -- highlight URLs by default
        notifications = false, -- disable notifications
      },
      sessions = {
        autosave = { last = true, cwd = true },
        ignore = {
          dirs = {},
          filetypes = { "gitcommit", "gitrebase" },
          buftypes = {},
        },
      },
    },
  },
}
