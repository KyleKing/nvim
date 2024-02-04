return {
    "chrisgrieser/nvim-early-retirement",
    event = "BufReadPost",
    opts = {
        retirementAgeMins = 60,
        minimumBufferNum = 20, -- Only when too many open buffers
        notificationOnAutoClose = true, -- Show notification on closing using nvim-notify

        -- When a file is deleted, for example via an external program, delete the associated buffer as well
        -- (This feature is independent from the automatic closing)
        deleteBufferWhenFileDeleted = true,
    },
}
