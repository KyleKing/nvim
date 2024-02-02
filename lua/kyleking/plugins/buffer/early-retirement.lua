return {
   "chrisgrieser/nvim-early-retirement",
   event = "BufReadPost",
   opts = {
      -- When a file is deleted, for example via an external program, delete the associated buffer as well
      deleteBufferWhenFileDeleted = true,
   },
}
