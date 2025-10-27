local p = premake

p.modules.export_compile_commands = {}
local m = p.modules.export_compile_commands

local workspace = p.workspace
local project = p.project

function m.getToolset(cfg)  
	local default = iif(cfg.system == p.WINDOWS, "msc", "clang")
  return p.tools[_OPTIONS.cc or cfg.toolset or default]
end

function m.getCommonFlags(cfg)
  local toolset = m.getToolset(cfg)
  local flags = toolset.getcppflags(cfg)

  if _OPTIONS['force_clang_defines'] then
    flags = table.join(flags, p.tools['clang'].getdefines(cfg.defines))
  else
    flags = table.join(flags, toolset.getdefines(cfg.defines))
  end

  flags = table.join(flags, toolset.getundefines(cfg.undefines))
  flags = table.join(flags, toolset.getforceincludes(cfg))
  flags = table.join(flags, toolset.getincludedirs(cfg, cfg.includedirs, cfg.externalincludedirs))
  flags = table.join(flags, toolset.getcxxflags(cfg))
  return table.join(flags, cfg.buildoptions)
end

function m.getObjectPath(prj, cfg, node)
  return path.join(cfg.objdir, path.appendExtension(node.objname, '.o'))
end

function m.getDependenciesPath(prj, cfg, node)
  return path.join(cfg.objdir, path.appendExtension(node.objname, '.d'))
end

function m.getFileFlags(prj, cfg, node)
  return table.join(m.getCommonFlags(cfg), {
    '-o', m.getObjectPath(prj, cfg, node),
    '-MF', m.getDependenciesPath(prj, cfg, node),
    '-c', node.abspath
  })
end

function m.generateCompileCommand(prj, cfg, node)
  local compiler = _OPTIONS['cc_path'] or 'cc'
  return {
    directory = prj.location,
    arguments = table.join({ compiler }, m.getFileFlags(prj, cfg, node)),
    file = node.abspath,
  }
end

function m.getProjectCommands(prj, cfg)
  local tr = project.getsourcetree(prj)
  local cmds = {}
  p.tree.traverse(tr, {
    onleaf = function(node, depth)
      if path.iscppfile(node.abspath) then
        table.insert(cmds, m.generateCompileCommand(prj, cfg, node))
      end
    end
  })
  return cmds
end

local function arguments_json_array(arguments)
  local json_args = {}
  for _, arg in ipairs(arguments) do
    table.insert(json_args, '"' .. arg:gsub('\\', '\\\\'):gsub('"', '\\"') .. '"')
  end
  return table.concat(json_args, ", ")
end

local function execute()
  local target_name = _OPTIONS['config'] or 'release'

  local cmds = {}
  for wks in p.global.eachWorkspace() do
    for prj in workspace.eachproject(wks) do
      for cfg in project.eachconfig(prj) do
        local cfgKey = string.format('%s', cfg.shortname)
        if cfgKey == target_name then
          cmds = table.join(cmds, m.getProjectCommands(prj, cfg))
        end
      end
    end

    local outfile = 'compile_commands.json'
    if _OPTIONS['out_dir'] then
      local localpath = path.join(_OPTIONS['out_dir'], 'compile_commands.json')
      outfile = path.getabsolute(path.join(wks.location or wks.basedir, localpath))
    end

    p.generate(wks, outfile, function(wks)
      p.w('[')
      for i = 1, #cmds do
        local item = cmds[i]
        local command = string.format([[
        {
          "directory": "%s",
          "file": "%s",
          "arguments": [%s]
        }]],
        item.directory,
        item.file,
        arguments_json_array(item.arguments))
        if i > 1 then
          p.w(',')
        end
        p.w(command)
      end
      p.w(']')
    end)
  end
end

newaction {
  trigger = 'export-compile-commands',
  description = 'Export compiler commands in JSON Compilation Database Format',
  execute = execute
}

newoption {
  trigger = 'cc_path',
  description = 'path that will be used in compile commands',
  default = 'cc'
}

newoption {
  trigger = 'config',
  description = 'configuration to use',
}

newoption {
  trigger = 'force_clang_defines',
  description = 'Used to fix issue when clangd on windows doesn\'t recognize msvc-style defines',
  default = false
}

newoption {
  trigger = 'out_dir',
  description = 'Output directory for compile_commands.json',
}

return m
