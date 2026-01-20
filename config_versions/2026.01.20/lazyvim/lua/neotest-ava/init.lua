local async = require("neotest.async")
local lib = require("neotest.lib")
local logger = require("neotest.logging")
local util = require("neotest-ava.util")
local ava_util = require("neotest-ava.ava-util")
local types = require("neotest.types")

local ResultStatus = types.ResultStatus

---@class neotest-ava.AvaArgumentContext
---@field config string?
---@field resultsPath string
---@field testNamePattern string

---@class neotest.AvaOptions
---@field avaCommand? string | fun(): string
---@field avaArguments? fun(defaultArguments: string[], avaArgsContext: neotest-ava.AvaArgumentContext): string[]
---@field avaConfigFile? string | fun(file_path: string): string
---@field env? table<string, string> | fun(): table<string, string>
---@field cwd? string | fun(): string
---@field strategy_config? table<string, unknown> | fun(): table<string, unknown>
---@field isTestFile async fun(file_path: string?): boolean

--@type neotest.Adapter
local adapter = { name = "neotest-ava" }

adapter.root = function(path)
  return lib.files.match_root_pattern("package.json")(path)
end

local getAvaCommand = ava_util.getAvaCommand
local getAvaArguments = ava_util.getAvaArguments
local getAvaConfig = ava_util.getAvaConfig
local isTestFile = ava_util.defaultIsTestFile

--@async
--@param file_path? string
--@return boolean
function adapter.is_test_file(path)
  return isTestFile(path)
end

function adapter.filter_dir(name)
  return name ~= "node_modules"
end

-- Enrich `it.each` tests with metadata about TS node position
function adapter.build_position(file_path, source, captured_nodes) end

---@async
---@return neotest.Tree | nil
function adapter.discover_positions(path) end

local function get_default_strategy_config(strategy, command, cwd)
  local config = {
    dap = function()
      return {
        name = "Debug Ava Tests",
        type = "pwa-node",
        request = "launch",
        args = { unpack(command, 2) },
        runtimeExecutable = command[1],
        console = "integratedTerminal",
        internalConsoleOptions = "neverOpen",
        rootPath = "${workspaceFolder}",
        cwd = cwd or "${workspaceFolder}",
      }
    end,
  }
  if config[strategy] then
    return config[strategy]()
  end
end

local function getEnv(specEnv)
  return specEnv
end

---@param path string
---@return string|nil
local function getCwd(path)
  return nil
end

local function getStrategyConfig(default_strategy_config, args)
  return default_strategy_config
end

local function cleanAnsi(s)
  return s:gsub("\x1b%[%d+;%d+;%d+;%d+;%d+m", "")
    :gsub("\x1b%[%d+;%d+;%d+;%d+m", "")
    :gsub("\x1b%[%d+;%d+;%d+m", "")
    :gsub("\x1b%[%d+;%d+m", "")
    :gsub("\x1b%[%d+m", "")
end

---@param args neotest.RunArgs
---@return neotest.RunSpec | nil
function adapter.build_spec(args) end

local function parsed_json_to_results(data, output_file, consoleOut)
  local tests = {}

  for _, testResult in pairs(data.asserts) do
    local testFn = testResult.name
    for _, assertionResult in pairs(testResult.assertionResults) do
      local status, name = assertionResult.status, assertionResult.title

      if name == nil then
        logger.error("Failed to find parsed test result ", assertionResult)
        return {}
      end

      local keyid = testFn

      for _, value in ipairs(assertionResult.ancestorTitles) do
        keyid = keyid .. "::" .. value
      end

      keyid = keyid .. "::" .. name

      if status == "pending" or status == "todo" then
        status = "skipped"
      end

      tests[keyid] = {
        status = status,
        short = name .. ": " .. status,
        output = consoleOut,
        location = assertionResult.location,
      }

      if not vim.tbl_isempty(assertionResult.failureMessages) then
        local errors = {}

        for i, failMessage in ipairs(assertionResult.failureMessages) do
          local msg = cleanAnsi(failMessage)
          local errorLine, errorColumn = findErrorPosition(testFn, msg)

          errors[i] = {
            line = (errorLine or assertionResult.location.line) - 1,
            column = (errorColumn or 1) - 1,
            message = msg,
          }

          tests[keyid].short = tests[keyid].short .. "\n" .. msg
        end

        tests[keyid].errors = errors
      end
    end
  end

  return tests
end

---@async
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@param tree neotest.Tree
---@return table<string, neotest.Result>
function adapter.results(spec, result, tree)
  spec.context.stop_stream()

  local output_file = spec.context.results_path

  local success, data = pcall(lib.files.read, output_file)

  if not success then
    logger.error("No test output file found ", output_file)
    return {}
  end

  local ok, parsed = pcall(vim.json.decode, data, { luanil = { object = true } })

  if not ok then
    logger.error("Failed to parse test output json ", output_file)
    return {}
  end

  local results = parsed_json_to_results(parsed, output_file, result.output)

  return results
end

---@generic T
---@param value T | fun(any): T
---@param default fun(any): T
---@param reject_value boolean?
---@return fun(any): T
local function resolve_config_option(value, default, reject_value)
  if util.is_callable(value) then
    return value
  elseif value and not reject_value then
    return function()
      return value
    end
  end

  return default
end

setmetatable(adapter, {
  ---@param opts neotest.AvaOptions
  __call = function(_, opts)
    getAvaCommand = resolve_config_option(opts.avaCommand, getAvaCommand)
    getAvaArguments = resolve_config_option(opts.avaArguments, getAvaArguments, true)
    getAvaConfig = resolve_config_option(opts.avaConfigFile, getAvaConfig)
    getCwd = resolve_config_option(opts.cwd, getCwd)
    getStrategyConfig = resolve_config_option(opts.strategy_config, getStrategyConfig)

    if util.is_callable(opts.env) then
      getEnv = opts.env
    elseif opts.env then
      getEnv = function(specEnv)
        return vim.tbl_extend("force", opts.env, specEnv)
      end
    end

    if util.is_callable(opts.isTestFile) then
      isTestFile = opts.isTestFile
    end

    return adapter
  end,
})

return adapter
