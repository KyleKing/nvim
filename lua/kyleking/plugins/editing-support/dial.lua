return {
   "monaqa/dial.nvim",
   keys = {
      { "<C-a>", "<Plug>(dial-increment)", mode = { "n", "v" }, desc = "Dial Increment" },
      { "<C-x>", "<Plug>(dial-decrement)", mode = { "n", "v" }, desc = "Dial Decrement" },
      { "g<C-a>", "g<Plug>(dial-increment)", mode = { "n", "v" }, remap = true, desc = "Dial Increment" },
      { "g<C-x>", "g<Plug>(dial-decrement)", mode = { "n", "v" }, remap = true, desc = "Dial Decrement" },
   },
   config = function()
      local augend = require("dial.augend")
      require("dial.config").augends:register_group({
         default = {
            augend.integer.alias.decimal, -- nonnegative decimal number (0, 1, 2, 3, ...)
            -- augend.integer.alias.hex, -- nonnegative hex number  (0x01, 0x1a1f, etc.)
            augend.constant.alias.bool, -- boolean value (true <-> false)
            augend.semver.alias.semver,
            augend.misc.alias.markdown_header,
            augend.constant.new({
               elements = { "and", "or" },
               word = true, -- if false, "sand" is incremented into "sor", "doctor" into "doctand", etc.
               cyclic = true, -- "or" is incremented into "and".
            }),
            augend.constant.new({
               elements = { "&&", "||" },
               word = false,
               cyclic = true,
            }),
            -- uppercase hex number (0x1A1A, 0xEEFE, etc.)
            augend.hexcolor.new({
               case = "lower",
            }),
         },
      })
   end,
}
