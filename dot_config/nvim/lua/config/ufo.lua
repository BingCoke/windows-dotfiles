vim.keymap.set("n", "zc", ":foldclose<CR>")

vim.keymap.set("n", "zv", ":foldopen<CR>")
vim.keymap.set("n", "zR", require("ufo").openAllFolds)
vim.keymap.set("n", "zM", require("ufo").closeAllFolds)
vim.keymap.set("n", "zr", require("ufo").openFoldsExceptKinds)
vim.keymap.set("n", "zm", require("ufo").closeFoldsWith) -- closeAllFolds == closeFoldsWith(0)

--vim.keymap.set("n", "zk", function()
--	local winid = require("ufo").peekFoldedLinesUnderCursor()
--	if not winid then
--		-- choose one of coc.nvim and nvim lsp
--		vim.lsp.buf.hover()
--	end
--end)

local handler = function(virtText, lnum, endLnum, width, truncate)
  local newVirtText = {}
  local suffix = (" 󰁂 %d "):format(endLnum - lnum)
  local sufWidth = vim.fn.strdisplaywidth(suffix)
  local targetWidth = width - sufWidth
  local curWidth = 0
  for _, chunk in ipairs(virtText) do
    local chunkText = chunk[1]
    local chunkWidth = vim.fn.strdisplaywidth(chunkText)
    if targetWidth > curWidth + chunkWidth then
      table.insert(newVirtText, chunk)
    else
      chunkText = truncate(chunkText, targetWidth - curWidth)
      local hlGroup = chunk[2]
      table.insert(newVirtText, { chunkText, hlGroup })
      chunkWidth = vim.fn.strdisplaywidth(chunkText)
      -- str width returned from truncate() may less than 2nd argument, need padding
      if curWidth + chunkWidth < targetWidth then
        suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
      end
      break
    end
    curWidth = curWidth + chunkWidth
  end
  table.insert(newVirtText, { suffix, "MoreMsg" })
  return newVirtText
end

require("ufo").setup({
  provider_selector = function(bufnr, filetype, buftype)
    if filetype == "dashboard" or filetype == "org" then
      return ""
    end

    return { "treesitter", "indent" }
  end,
  fold_virt_text_handler = handler,
})



--local buffer = require("ufo.model.buffer")
--local orig_lines = buffer.lines
--function buffer:lines(lnum, endLnum)
--  if self:lineCount() < lnum then
--    self:reload()
--  end
--  local lineCount = self:lineCount()
--  if lineCount < lnum then
--    return { "" }
--  end
--  endLnum = endLnum or lnum
--  if endLnum < 0 then
--    endLnum = lineCount + endLnum + 1
--  end
--  if endLnum > lineCount then
--    endLnum = lineCount
--  end
--  if endLnum < lnum then
--    return { "" }
--  end
--  return orig_lines(self, lnum, endLnum)
--end
