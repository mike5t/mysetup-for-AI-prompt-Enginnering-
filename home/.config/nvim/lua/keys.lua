-- Save file by pressing Escape in Insert Mode
vim.keymap.set("i", "<Esc>", "<Esc>:w<CR>", { desc = "Escape and Save" })
vim.keymap.set("n", "<Esc>", ":w<CR>", { desc = "Save in Normal Mode" })

-- Ctrl+A to select everything
vim.keymap.set("n", "<C-a>", "ggVG", { desc = "Select All" })

-- Prevent visual paste from overwriting the clipboard register
vim.keymap.set("v", "p", '"_dP', { desc = "Paste without yanking replaced text" })
