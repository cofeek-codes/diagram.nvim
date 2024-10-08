---@class PlantUMLOptions
---@field charset? string

---@type table<string, string>
local cache = {} -- session cache

---@class Renderer<PlantUMLOptions>
local M = {
  id = "plantuml",
}

-- fs cache
local tmpdir = vim.fn.resolve(vim.fn.stdpath("cache") .. "/diagram-cache/plantuml")
vim.fn.mkdir(tmpdir, "p")

---@param source string
---@param options PlantUMLOptions
---@return string|nil
M.render = function(source, options)
  local hash = vim.fn.sha256(M.id .. ":" .. source)
  if cache[hash] then return cache[hash] end

  local path = vim.fn.resolve(tmpdir .. "/" .. hash .. ".png")
  if vim.fn.filereadable(path) == 1 then return path end

  if not vim.fn.executable("plantuml") then error("diagram/plantuml: plantuml not found in PATH") end

  local tmpsource = vim.fn.tempname()
  vim.fn.writefile(vim.split(source, "\n"), tmpsource)

  local command_parts = {
    "plantuml",
    "-tpng",
    "-pipe",
  }
  if options.charset then
    table.insert(command_parts, "-charset")
    table.insert(command_parts, options.charset)
  end
  table.insert(command_parts, "<")
  table.insert(command_parts, tmpsource)

  local command = table.concat(command_parts, " ")
  local output = vim.fn.system(command .. " > " .. vim.fn.shellescape(path))
  if vim.v.shell_error ~= 0 then
    vim.notify("diagram/plantuml: plantuml failed to render diagram. Error: " .. output, vim.log.levels.ERROR)
    return nil
  end

  cache[hash] = path
  return path
end

return M
