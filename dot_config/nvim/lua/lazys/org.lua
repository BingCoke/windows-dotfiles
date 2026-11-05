return {
  "xheisenbugx/org.nvim",
  main = "org",
  lazy = false, -- startup cost is small: heavy modules load on first use
  opts = {
    org_directory = "~/org",
    agenda_files = { "~/org/**/*.org" },
    default_notes_file = "~/org/refile.org",
    mappings = {
      agenda = {
        kill = "<BS>",
        show_scroll_down = false,
      },
    },
  },
}
