return {
  "nanozuki/tabby.nvim",
  event = "VeryLazy",
  config = function()
    
    vim.api.nvim_set_keymap("n", "<leader>na", "<cmd>tabnew<CR>", { noremap = true })
    vim.api.nvim_set_keymap("n", "<leader>no", "<cmd>tabonly<CR>", { noremap = true })

    vim.keymap.set("n", "<leader>nf", "<cmd>tabnew %<cr>", { noremap = true })

    vim.api.nvim_set_keymap("n", "<M-w>", ":tabclose<CR>", { noremap = true })

    vim.api.nvim_set_keymap("n", "<C-l>", ":tabn<CR>", { noremap = true })
    vim.api.nvim_set_keymap("n", "<C-h>", ":tabp<CR>", { noremap = true })

    -- move current tab to previous position
    vim.api.nvim_set_keymap("n", "<M-i>", ":-tabmove<CR>", { noremap = true })
    -- move current tab to next position
    vim.api.nvim_set_keymap("n", "<M-o>", ":+tabmove<CR>", { noremap = true })

    vim.keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
    -- split window vertically
    vim.keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
    for i = 1, 8, 1 do
      vim.keymap.set("n", "<leader>" .. i, i .. "gt")
    end

    local theme = {
      fill = "TabLineFill",
      -- Also you can do this: fill = { fg='#f2e9de', bg='#907aa9', style='italic' }
      head = "TabLine",
      current_tab = "TabLineSel",
      tab = "TabLine",
      win = "TabLine",
      tail = "TabLine",
    }

    local function get_special_buf_name(bufid)
      local ft = vim.bo[bufid].filetype
      if ft == "OverseerList" then
        return "OverseerList"
      end
      if ft == "OverseerOutput" then
        return "OverseerListput"
      end
      if ft == "TelescopePrompt" then
        return "telescope"
      end
      if ft == "NvimTree" then
        return "󰙅 Files"
      end
      if ft == "oil" then
        local path = vim.api.nvim_buf_get_name(bufid):gsub("^oil://", ""):gsub("/$", "")
        return "󰉋 " .. vim.fn.fnamemodify(path, ":t") .. "/"
      end
      if ft == "fugitive" then
        return " Git"
      end
      if ft == "lazy" then
        return "󰒲 Lazy"
      end
      -- 返回 nil 走默认逻辑
    end

    require("tabby").setup({
      option = {
        tab_name = {
          -- tab 名称的 override：取当前 window 的 buf，特殊处理
          name_fallback = function(tabid)
            local winid = vim.api.nvim_tabpage_get_win(tabid)
            local bufid = vim.api.nvim_win_get_buf(winid)
            local r = get_special_buf_name(bufid)
                or vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufid), ":t")
            return r == "" and "none" or r
          end,
        },
        buf_name = {
          mode = "unique", -- or 'relative', 'tail', 'shorten'
          name_fallback = function(bufid)
            return "[No Name]"
          end,
          override = nil,
        },
      },
      line = function(line)
        local function hex_to_rgb(color)
          if not color or color == "NONE" then
            return nil, nil, nil
          end

          local hex = color:gsub("#", "")
          return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
        end

        local function shade_color(color, percent)
          local r, g, b = hex_to_rgb(color)
          if not r or not g or not b then
            return color
          end

          local function alter(value)
            return math.min(math.floor(value * (100 + percent) / 100), 255)
          end

          return string.format("#%02x%02x%02x", alter(r), alter(g), alter(b))
        end

        local function color_is_bright(color)
          local r, g, b = hex_to_rgb(color)
          if not r or not g or not b then
            return false
          end

          return (0.299 * r + 0.587 * g + 0.114 * b) / 255 > 0.5
        end

        local function get_hl_color(groups, attribute, fallback, not_match)
          groups = type(groups) == "table" and groups or { groups }

          for _, name in ipairs(groups) do
            local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
            local value = ok and hl[attribute] or nil
            if value then
              local color = string.format("#%06x", value)
              if color ~= not_match then
                return color
              end
            end
          end

          return fallback
        end

        local function get_tab_bg(hl)
          if type(hl) == "table" and hl.bg then
            return hl.bg
          end

          return get_hl_color(hl, "bg", get_hl_color("Normal", "bg", "NONE"))
        end

        local normal_fg = get_hl_color("Normal", "fg", "#c0caf5")
        local normal_bg = get_hl_color({ "TabLine", "Normal" }, "bg", "#1f2335")
        local comment_fg = get_hl_color("Comment", "fg", normal_fg)
        local tabline_fg = get_hl_color("TabLine", "fg", comment_fg)
        local tabline_bg = get_hl_color("TabLine", "bg", normal_bg)
        local tabline_sel_fg = get_hl_color("TabLineSel", "bg", nil, normal_bg)
          or get_hl_color("TabLineSel", "fg", nil, normal_bg)
          or get_hl_color("WildMenu", "fg", normal_fg)
        local is_bright_background = color_is_bright(normal_bg)

        local fill_bg = shade_color(tabline_bg, is_bright_background and -6 or 8)
        local tab_bg = shade_color(tabline_bg, is_bright_background and -4 or 12)
        local current_bg = shade_color(normal_bg, is_bright_background and -3 or 6)

        local diag_colors = {
          error = get_hl_color({ "DiagnosticError", "LspDiagnosticsDefaultError", "DiffDelete" }, "fg", "#e32636"),
          warn = get_hl_color({ "DiagnosticWarn", "LspDiagnosticsDefaultWarning", "DiffText" }, "fg", "#ffa500"),
        }

        local signs = {
          [vim.diagnostic.severity.ERROR] = { icon = " ", fg = diag_colors.error },
          [vim.diagnostic.severity.WARN] = { icon = " ", fg = diag_colors.warn },
        }

        local function get_buf_diagnostic(bufnr)
          local counts = vim.diagnostic.count(bufnr)
          if (counts[vim.diagnostic.severity.ERROR] or 0) > 0 then
            return signs[vim.diagnostic.severity.ERROR]
          elseif (counts[vim.diagnostic.severity.WARN] or 0) > 0 then
            return signs[vim.diagnostic.severity.WARN]
          end
          return nil
        end

        local function tab_modified(tab)
          for _, win in ipairs(tab.wins().wins) do
            if win.buf().is_changed() then
              return "●"
            end
          end
          return ""
        end

        local theme = {
          fill = { fg = comment_fg, bg = fill_bg },
          head = { fg = tabline_fg, bg = tab_bg },
          current_tab = { fg = tabline_sel_fg, bg = current_bg, bold = true },
          tab = { fg = tabline_fg, bg = tab_bg },
          win = { fg = tabline_fg, bg = tab_bg },
          tail = { fg = tabline_fg, bg = tab_bg },
        }

        return {
          { " ", hl = theme.head },
          line.tabs().foreach(function(tab)
            local hl = tab.is_current() and theme.current_tab or theme.tab
            local bg = get_tab_bg(hl)
            local win = vim.api.nvim_tabpage_get_win(tab.id)
            local buf = vim.api.nvim_win_get_buf(win)
            local diag = get_buf_diagnostic(buf)
            return {
              tab.number(),
              tab.name(),
              diag and { diag.icon .. "", hl = { fg = diag.fg, bg = bg } } or "",
              tab_modified(tab),
              tab.close_btn(" "),
              hl = hl,
              margin = " ",
            }
          end),
          line.spacer(),
          hl = theme.fill,
        }
      end,
      -- option = {}, -- setup modules' option,
    })
  end,
}
