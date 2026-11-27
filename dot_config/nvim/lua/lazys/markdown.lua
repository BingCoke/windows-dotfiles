local function render_tasks(ctx)
  local query = vim.treesitter.query.parse("markdown", [[
       (list_item [
         (list_marker_minus)
         (list_marker_plus)
         (list_marker_star)
         (list_marker_dot)
         (list_marker_parenthesis)
       ] @marker)
     ]])

  local marks = {}
  for _, marker in query:iter_captures(ctx.root, ctx.buf) do
    local row, _, _, marker_end = marker:range()
    local line = vim.api.nvim_buf_get_lines(ctx.buf, row, row + 1, false)[1]
    local state, box_end = line:sub(marker_end + 1)
        :match("^%[([ \t]*[xX%-]?[ \t]*)%]%f[%s%z]()")

    if state then
      local highlight = ({
        [""] = "DiagnosticError",
        ["-"] = "DiagnosticWarn",
        x = "DiagnosticOk",
      })[vim.trim(state):lower()]

      marks[#marks + 1] = {
        conceal = false,
        start_row = row,
        start_col = marker_end,
        opts = {
          end_col = marker_end + box_end - 1,
          hl_group = highlight,
          priority = 200,
        },
      }
    end
  end

  return marks
end

  local function render_latex(ctx)
     local marks = require("render-markdown.handler.latex").parse(ctx)
     local highlight = "MarkdownMathPreview"

     for _, mark in ipairs(marks) do
       if not mark.opts.virt_lines_above then
         local rows = {}
         local indent
         local width = 0

         for _, line in ipairs(mark.opts.virt_lines or {}) do
           local chunk = line[#line]
           if chunk and chunk[2] == highlight then
             local text = chunk[1]:gsub(" +$", "")
             rows[#rows + 1] = { line = line, text = text }

             if text ~= "" then
               local spaces = #text:match("^ *")
               indent = math.min(indent or spaces, spaces)
               width = math.max(width, vim.fn.strdisplaywidth(text))
             end
           end
         end

         if indent then
           local prefix = string.rep(" ", indent)
           local body_width = width - indent

           for _, row in ipairs(rows) do
             local text = row.text:sub(indent + 1)
             local right = string.rep(" ", body_width - vim.fn.strdisplaywidth(text))
             local line = row.line

             line[#line] = nil
             if prefix ~= "" then
               line[#line + 1] = { prefix }
             end
             line[#line + 1] = { text .. right, highlight }
           end
         end
       end
     end

     return marks
   end

return {
  {
    "freeo/md-table.nvim",
    cmd = "MdTable",
    keys = { { "<leader>mt", "<cmd>MdTable<cr>", desc = "Read table" } }
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    lazy = false,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)
      vim.api.nvim_set_hl(0, "MarkdownMathPreview", {
        fg = "#c8d3f5",
        bg = "#2f334d",
      })
    end,
    opts = {
      win_options = {
        conceallevel = {
          default = 0,
          rendered = 3,
        },
      },
      anti_conceal = {
        ignore = {
          quote = true,
          code_background = false,
          code_border = true,
          code_language = true,
          head_background = false,
        },
      },
      code = {
        -- 不把 ``` 显示出来
        conceal_delimiters = true,

        -- 开启代码块上下分隔线
        border = "thick",
        width = "full",

        -- 保留开头的语言图标和语言名
        language = true,
        language_icon = true,
        language_name = true,
        language_info = false,

        -- 语言信息放在左侧
        position = "left",

        -- 不额外增加左右空格
        left_pad = 0,
        right_pad = 0,
      },
      heading = { position = "overlay", setext = false },
      --code = { conceal_delimiters = false },

      checkbox = { enabled = false },
      bullet = { enabled = false },
      link = { enabled = false },
      --quote = { enabled = false },
      latex = {
        enabled = true,
        render_modes = { "i" },
        inline = true,
        block = true,
        position = "below",
        highlight = "MarkdownMathPreview",
      },



      pipe_table = { enabled = false },

      custom_handlers = {
        markdown = { extends = true, parse = render_tasks },
        latex = {
          parse = render_latex
        }
      },
    },
    keys = {
      { "<leader>mr", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle Markdown rendering" },
    },
  },
  {
    "HakonHarnes/img-clip.nvim",
    ft = { "markdown" },
    opts = {},
    keys = {
      { "<leader>pi", "<cmd>PasteImage<cr>", ft = "markdown", desc = "Paste image" },
    },
  },
  {
    "3rd/image.nvim",
    build = false,
    ft = { "markdown" },
    opts = {
      backend = "kitty",
      processor = "magick_cli",
      window_overlap_clear_enabled = true,
      window_overlap_clear_ft_ignore = {
        "cmp_menu",
        "cmp_docs",
        "snacks_notif",
        "scrollview",
        "scrollview_sign",
      },
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
        },
      },
      max_height_window_percentage = 50,
    },
  },
}
