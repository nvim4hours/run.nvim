local M = {}
local vim = vim

local config = {
  enabled = true,
  handlers = {
    { ext = "java", action = "javac [name].[ext] && java [name]" },
    { ext = "py",   action = "python3 [name].[ext]" },
    { ext = "go",   action = "go run [name].[ext]" },
    { ext = "js",   action = "node [name].[ext]" },
    { ext = "rs",   action = "cargo run [name].[ext]" },
  },
  split_cmd = "botright split | resize -10"
}

local function random_char()
  local characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789`~!@#$%^&*)(-=][\';\"/.,_+}{|:?><"
  local random_index = math.random(1, string.len(characters))
  local picked_character = string.sub(characters, random_index, random_index)
  return picked_character
end

function M.run()
  if not config.enabled then return end

  local dir, name, ext = vim.fn.expand("%:p:h"), vim.fn.expand("%:t:r"), vim.fn.expand("%:e")
  for _, h in ipairs(config.handlers) do
    if h.ext == ext then
      local cmd = h.action:gsub("%[name%]", name):gsub("%[ext%]", ext)

      -- open a split to show output
      vim.cmd(config.split_cmd)
      vim.cmd("enew")
      local buf = vim.api.nvim_get_current_buf()
      vim.api.nvim_buf_set_name(buf, "crunner: " .. name .. "." .. ext .. "_" .. random_char() .. random_char())
      vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
      vim.api.nvim_buf_set_option(buf, "bufhidden", "hide") -- hide on close
      vim.api.nvim_buf_set_option(buf, "buflisted", false)  -- not in tabline
      vim.api.nvim_buf_set_option(buf, "swapfile", false)
      vim.api.nvim_buf_set_option(buf, "filetype", "crunner")

      -- run command asynchronously
      vim.fn.jobstart("cd " .. dir .. " &&" .. cmd, {
        stdout_buffered = true,
        stderr_buffered = true,
        on_stdout = function(_, data)
          if data then vim.api.nvim_buf_set_lines(buf, -1, -1, false, data) end
        end,
        on_stderr = function(_, data)
          if data then vim.api.nvim_buf_set_lines(buf, -1, -1, false, data) end
        end,
      })

      return
    end
  end

  print("No handler configured for extension: " .. ext)
end

function M.setup(opts)
  if opts then config = vim.tbl_deep_extend("force", config, opts) end
end

return M
