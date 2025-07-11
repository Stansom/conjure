-- [nfnl] fnl/conjure/client/javascript/stdio.fnl
local _local_1_ = require("conjure.nfnl.module")
local autoload = _local_1_["autoload"]
local define = _local_1_["define"]
local a = autoload("nfnl.core")
local str = autoload("nfnl.string")
local stdio = autoload("conjure.remote.stdio")
local config = autoload("conjure.config")
local mapping = autoload("conjure.mapping")
local client = autoload("conjure.client")
local log = autoload("conjure.log")
local text = autoload("conjure.text")
local M = define("conjure.client.javascript.stdio", {})
config.merge({client = {javascript = {stdio = {command = "node --experimental-repl-await -i", ["prompt-pattern"] = "> "}}}})
if config["get-in"]({"mapping", "enable_defaults"}) then
  config.merge({client = {javascript = {stdio = {mapping = {start = "cs", stop = "cS", restart = "cr", interrupt = "ei"}}}}})
else
end
local cfg = config["get-in-fn"]({"client", "javascript", "stdio"})
local state
local function _3_()
  return {repl = nil}
end
state = client["new-state"](_3_)
M["buf-suffix"] = ".js"
M["comment-prefix"] = "// "
M["form-node?"] = function(node)
  return (("function_declaration" == node:type()) or ("export_statement" == node:type()) or ("try_statement" == node:type()) or ("expression_statement" == node:type()) or ("import_statement" == node:type()) or ("class_declaration" == node:type()) or ("lexical_declaration" == node:type()) or ("for_statement" == node:type()))
end
local function with_repl_or_warn(f, opts)
  local repl = state("repl")
  if repl then
    return f(repl)
  else
    return log.append({(M["comment-prefix"] .. "No REPL running"), (M["comment-prefix"] .. "Start REPL with " .. config["get-in"]({"mapping", "prefix"}) .. cfg({"mapping", "start"}))})
  end
end
local function display_result(msg)
  return log.append(msg)
end
local function replace_require_path(s, cwd)
  if string.find(s, "require") then
    local function _5_(m)
      if text["starts-with"](m, "./") then
        return ("require(\"" .. cwd .. m:sub(2) .. "\")")
      else
        return ("require(\"" .. m .. "\")")
      end
    end
    return string.gsub(s, "require%(\"(.-)\"%)", _5_)
  else
    return s
  end
end
local patterns_replacements = {{"^%s*import%s+%{%s*([^}]+)%s+as%s+([^}]+)%s+%}%s+from%s+[\"'](%w+:?%w+)[\"']%s*;?%s?", "const {%1:%2} = require(\"%3\");"}, {"^%s*import%s+([^%s{]+)%s+from%s+([\"'])(.-)%2%s*;?%s?", "const %1 = require(\"%3\");"}, {"^%s*import%s+%*%s+as%s+([^%s]+)%s+from%s+([\"'])(.-)%2%s*;?%s?", "const %1 = require(\"%3\");"}, {"^%s*import%s+%{([^}]+)%}%s+from%s+([\"'])(.-)%2%s*;?%s?", "const {%1} = require(\"%3\");"}, {"^%s*import%s+([^%s{,]+)%s*,%s*%{([^}]+)%}%s+from%s+([\"'])(.-)%3%s*;?%s?", "const { default: %1, %2 } = require(\"%4\");"}, {"^%s*import%s+([\"'])(.-)%1%s*;?%s?", "require(\"%2\");"}}
local function replace_imports(s)
  if text["starts-with"](s, "import") then
    local initial_acc = {result = s, ["applied?"] = false}
    local final_acc
    local function _9_(acc, _8_)
      local pat = _8_[1]
      local repl = _8_[2]
      if acc["applied?"] then
        return acc
      else
        local r, c = string.gsub(acc.result, pat, repl)
        if (c > 0) then
          return {["applied?"] = true, result = r}
        else
          return acc
        end
      end
    end
    final_acc = a.reduce(_9_, initial_acc, patterns_replacements)
    return final_acc.result
  else
    return s
  end
end
local function is_arrow_fn_3f(s)
  if ("string" ~= type(s)) then
  else
  end
  local ts = s:match("^%s*(.-)%s*$")
  local expr = (ts:match("=%s*(.*)") or ts)
  local parens = "^%s*%b()%s*=>"
  local ident = "^%s*[%a_$][%w_$]*%s*=>"
  if not (ts:find("=> ") or ts:find("%f[%w]function%f[%W]")) then
  else
  end
  if expr:match(parens) then
  else
  end
  if expr:match(ident) then
  else
  end
  return false
end
local function replace_arrows(s)
  if not is_arrow_fn_3f(s) then
    return s
  else
    local function _17_(name, before_args, args, body)
      local async_kw
      if before_args:find("async") then
        async_kw = "async "
      else
        async_kw = ""
      end
      local final_body
      if body:find("^%s*%{") then
        final_body = (" " .. body)
      else
        final_body = (" { return " .. body .. " }")
      end
      return (async_kw .. "function " .. name .. "(" .. args .. ")" .. final_body)
    end
    return s:gsub("const%s*([%w_]+)%s*=%s*(.-)%((.-)%)%s*=>%s*(.*)", _17_)
  end
end
local function prep_code(s)
  local function _21_(_241)
    return replace_require_path(replace_imports(str.trim(_241)), vim.uv.fs_realpath(vim.fn.expand("%:p:h")))
  end
  local function _22_(_241)
    return ("" ~= _241)
  end
  return (str.join("\n", a.map(_21_, a.filter(_22_, str.split(replace_arrows(s), "\n")))) .. "\n")
end
local function replace_dots(s, with)
  local s0, _count = string.gsub(s, "%.%.%.%s?", with)
  return s0
end
M["format-msg"] = function(msg)
  local function _23_(_241)
    return replace_dots(_241, "")
  end
  local function _24_(_241)
    return ("" ~= _241)
  end
  return a.map(_23_, a.filter(_24_, str.split(msg, "\n")))
end
local function sanitize_msg(msg, field)
  local function _25_(_241)
    return ("(" .. field .. ") " .. _241 .. "\n")
  end
  local function _26_(...)
    return not str["blank?"](...)
  end
  local function _27_(_241)
    return replace_dots(_241, "")
  end
  return str.join("", a.map(_25_, a.filter(_26_, a.map(_27_, str.split(a.get(msg, field), "\n")))))
end
local function prepare_out(msg)
  if a.get(msg, "out") then
    return sanitize_msg(msg, "out")
  elseif a.get(msg, "err") then
    return sanitize_msg(msg, "err")
  else
    return nil
  end
end
M.unbatch = function(msgs)
  return str.join("", a.map(prepare_out, msgs))
end
M["eval-str"] = function(opts)
  local function _29_(repl)
    local function _30_(msgs)
      local msgs0 = M["format-msg"](M.unbatch(msgs))
      display_result(msgs0)
      if opts["on-result"] then
        return opts["on-result"](str.join(" ", msgs0))
      else
        return nil
      end
    end
    return repl.send(prep_code(opts.code), _30_, {["batch?"] = true})
  end
  return with_repl_or_warn(_29_)
end
M["eval-file"] = function(opts)
  return M["eval-str"](a.assoc(opts, "code", a.slurp(opts["file-path"])))
end
local function display_repl_status(status)
  local repl = state("repl")
  if repl then
    return log.append({(M["comment-prefix"] .. a["pr-str"](a["get-in"](repl, {"opts", "cmd"})) .. " (" .. status .. ")")}, {["break?"] = true})
  else
    return nil
  end
end
M.stop = function()
  local repl = state("repl")
  if repl then
    repl.destroy()
    display_repl_status("stopped")
    return a.assoc(state(), "repl", nil)
  else
    return nil
  end
end
M["initialise-repl-code"] = ""
M.start = function()
  if state("repl") then
    return log.append({(M["comment-prefix"] .. "Can't start, REPL is already running."), (M["comment-prefix"] .. "Stop the REPL with " .. config["get-in"]({"mapping", "prefix"}) .. cfg({"mapping", "stop"}))}, {["break?"] = true})
  else
    local function _34_()
      display_repl_status("started")
      local function _35_(repl)
        local function _36_(msgs)
          return display_result(M["format-msg"](M.unbatch(msgs)))
        end
        return repl.send(prep_code(M["initialise-repl-code"]), _36_, {batch = true})
      end
      return with_repl_or_warn(_35_)
    end
    local function _37_(err)
      return display_repl_status(err)
    end
    local function _38_(code, signal)
      if (("number" == type(code)) and (code > 0)) then
        log.append({(M["comment-prefix"] .. "process exited with code " .. code)})
      else
      end
      if (("number" == type(signal)) and (signal > 0)) then
        log.append({(M["comment-prefix"] .. "process exited with signal " .. signal)})
      else
      end
      return M.stop()
    end
    local function _41_(msg)
      return log.dbg(M["format-msg"](M.unbatch({msg})), {["join-first?"] = true})
    end
    return a.assoc(state(), "repl", stdio.start({["prompt-pattern"] = cfg({"prompt-pattern"}), cmd = cfg({"command"}), ["delay-stderr-ms"] = cfg({"delay-stderr-ms"}), ["on-success"] = _34_, ["on-error"] = _37_, ["on-exit"] = _38_, ["on-stray-output"] = _41_}))
  end
end
local function warning_msg()
  local function _43_(_241)
    return log.append({_241})
  end
  return a.map(_43_, {"// WARNING! Node.js REPL limitations require transformations:", "// 1. ES6 'import' statements are converted to 'require(...)' calls.", "// 2. Arrow functions ('const fn = () => ...') are converted to 'function fn() ...' declarations to allow re-definition."})
end
M["on-load"] = function()
  if config["get-in"]({"client_on_load"}) then
    M.start()
    return warning_msg()
  else
    return log.append({"Not starting repl"})
  end
end
M["on-exit"] = function()
  return M.stop()
end
M.interrupt = function()
  local function _45_(repl)
    log.append({(M["comment-prefix"] .. " Sending interrupt signal.")}, {["break?"] = true})
    return repl["send-signal"]("sigint")
  end
  return with_repl_or_warn(_45_)
end
M["on-filetype"] = function()
  mapping.buf("JavascriptStart", cfg({"mapping", "start"}), M.start, {desc = "Start the Javascript REPL"})
  mapping.buf("JavascriptStop", cfg({"mapping", "stop"}), M.stop, {desc = "Stop the Javascript REPL"})
  local function _46_()
    M.stop()
    return M.start()
  end
  mapping.buf("JavascriptRestart", cfg({"mapping", "restart"}), _46_, {desc = "Restart the Javascript REPL"})
  return mapping.buf("JavascriptInterrupt", cfg({"mapping", "interrupt"}), M.interrupt, {desc = "Interrupt the current evaluation"})
end
return M
