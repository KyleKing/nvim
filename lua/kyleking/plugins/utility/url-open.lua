-- PLANNED: support JIRA tickets [PPLMS-\d+]
return {
    "sontungexpt/url-open",
    event = "BufRead",
    cmd = "URLOpenUnderCursor",
    opts = {},
    keys = {
        { "<leader>uu", "<esc>:URLOpenUnderCursor<cr>", desc = "Open URL" },
    },
}
