local M = {}

local lib = require("neotest.lib")
local util = require("neotest-ava.util")
local compat = require("neotest-jest.compat")
local uv = compat.uv
local rootPackageJsonPath = uv.cwd() .. "/package.json"
local avaConfigPattern = util.root_pattern("ava.config.{js,ts,mjs,cjs}")

-- Returns ava binary from `node_modules` if that binary exists and `ava` otherwise.
---@param path string
---@return string
function M.getAvaCommand(path)
  local gitAncestor = util.find_git_ancestor(path)

  local function findBinary(p)
    local rootPath = util.find_node_modules_ancestor(p)

    if not rootPath then
      -- We did not find a root path so bail out since we already searched a
      -- lot of parent directories. Otherwise we would compare a nil value
      -- with a possible non-nil gitAncestor path resulting in infinite
      -- recursion
      return
    end

    local avaBinary = util.path.join(rootPath, "node_modules", ".bin", "ava")

    if util.path.exists(avaBinary) then
      return avaBinary
    end

    -- If no binary found and the current directory isn't the parent
    -- git ancestor, let's traverse up the tree again
    if rootPath ~= gitAncestor then
      return findBinary(util.path.dirname(rootPath))
    end
  end

  local foundBinary = findBinary(path)

  if foundBinary then
    return foundBinary
  end

  return "ava"
end

-- Returns jest config file path if it exists.
---@param path string
---@return string|nil
function M.getAvaConfig(path)
  local rootPath = avaConfigPattern(path)

  if not rootPath then
    return nil
  end

  local avaJs = util.path.join(rootPath, "jest.config.js")
  local avaTs = util.path.join(rootPath, "jest.config.ts")
  local avaMJs = util.path.join(rootPath, "jest.config.mjs")
  local avaCJs = util.path.join(rootPath, "jest.config.cjs")

  if util.path.exists(avaTs) then
    return avaTs
  elseif util.path.exists(avaMJs) then
    return avaMJs
  elseif util.path.exists(avaCJs) then
    return avaCJs
  end

  return avaJs
end

local function checkPackageFieldsForAva(parsedPackageJson)
  local fields = { "dependencies", "devDependencies" }

  for _, field in ipairs(fields) do
    if parsedPackageJson[field] then
      for key, _ in pairs(parsedPackageJson[field]) do
        if key == "ava" then
          return true
        end
      end
    end
  end

  if parsedPackageJson["scripts"] then
    for _, value in pairs(parsedPackageJson["scripts"]) do
      if value == "ava" then
        return true
      end
    end
  end

  return false
end

---@param path string
---@return boolean
function M.packageJsonHasAvaDependency(path)
  local read_success, packageJsonContent = pcall(lib.files.read, path)

  if not read_success then
    vim.notify("cannot read package.json", vim.log.levels.ERROR)
    return false
  end

  local parse_success, parsedPackageJson = pcall(vim.json.decode, packageJsonContent)

  if not parse_success then
    vim.notify("cannot parse package.json", vim.log.levels.ERROR)
    return false
  end

  return checkPackageFieldsForAva(parsedPackageJson)
end

---@async
---@param path string?
---@return boolean
function M.hasAvaDependency(path)
  if not path then
    return false
  end

  local rootPath = lib.files.match_root_pattern("package.json")(path)

  if not rootPath then
    return false
  end

  if M.packageJsonHasAvaDependency(rootPath .. "/package.json") then
    return true
  end

  return M.packageJsonHasAvaDependency(rootPackageJsonPath)
end

function M.defaultIsTestFile(file_path)
  if not file_path then
    return false
  end

  return util.defaultTestFileMatcher(file_path) and M.hasJestDependency(file_path)
end

return M
