------@class LazyPluginSpec
---return {
---    "https://gitlab.com/itaranto/preview.nvim",
---    dependencies = {
---        "aklt/plantuml-syntax",
---    },
---    -- Adapted from: https://github.com/ariefra/ar.nvim/blob/1444607e70a6639c68271e38603008f06859c5ae/lua/base/preview.lua
---    -- and: https://github.com/cristianrgreco/nvim/blob/252d8a7c5996444d7194240ed1e3d2e4df33a6e6/lua/plugins/preview.nvim.lua
---    -- and: https://gitlab.com/itaranto/preview.nvim/-/issues/4#note_2203787288
---    cmd = { "PreviewFile" },
---    ft = { "plantuml" },
---    opts = {
---        previewers_by_ft = {
---            plantuml = {
---                -- name = "plantuml_png",
---                -- renderer = { type = "command", opts = { cmd = { "open", "-a", "Preview" } } },
---                -- renderer = { type = "command", opts = { cmd = { "open" } } },
---                name = "plantuml_text",
---                renderer = { type = "buffer", opts = { split_cmd = "split" } },
---            },
---        },
---        -- previewers = {
---        --     plantuml_png = {
---        --         args = { "-pipe", "-tpng" },
---        --     },
---        -- },
---        render_on_write = true,
---    },
---}

return {
    {
        "https://gitlab.com/itaranto/preview.nvim",
        version = "*",
        lazy = false,
        dependencies = {
            "aklt/plantuml-syntax",
        },
        opts = {
            previewers_by_ft = {
                plantuml = {
                    name = "plantuml_text",
                    renderer = { type = "buffer" },
                },
            },
        },
    },
}
