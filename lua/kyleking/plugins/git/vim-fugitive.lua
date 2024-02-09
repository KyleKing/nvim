-- PLANNED: take a look at https://youtu.be/IyBAuDPzdFY?si=wR9QTOa74HxQwIbT for fugitive features
return {
    "tpope/vim-fugitive",
    dependencies = {
        "tpope/vim-rhubarb",
    },
    cmd = {
        "G",
        "Git",
        "Gvdiffsplit",
        "Gread",
        "Gwrite",
        "Ggrep",
        "GMove",
        "GDelete",
        "GBrowse",
        "GRemove",
        "GRename",
        "Glgrep",
        "Gedit",
    },
    ft = { "fugitive" },
}
