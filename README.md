## Generate compile_commands.json for premake projects

This module implements [JSON Compilation Database Format
Specification](http://clang.llvm.org/docs/JSONCompilationDatabase.html) for
premake projects.

Install this module somewhere premake can find it, for example:

```
git clone https://github.com/tarruda/premake-export-compile-commands export-compile-commands
```

Then put this at the top of your system script(eg: ~/.premake/premake-system.lua):

```lua
require "export-compile-commands"
```

Note that while possible, it is not recommended to put the `require` line in
project-specific premake configuration because the "export-compile-commands"
module will need to be installed everywhere your project is built.

After the above steps, the "export-compile-commands" action will be available
for your projects:

```
premake5 export-compile-commands
```

The `export-compile-commands` action generates a `compile_commands.json` file
in the workspace directory (or in the directory specified by the `out_dir` option)
for the release configuration. This file contains the compilation commands for
all C/C++ source files in your projects.

### Usage Examples

#### Basic usage
Generate compile commands with default settings (uses the release configuration):
```bash
premake5 export-compile-commands
```

#### Using a specific config
Generate compile commands with a specific configuration:
```bash
premake5 export-compile-commands --config=debug
```

#### Using a specific compiler
Generate compile commands using clang++:
```bash
premake5 export-compile-commands --cc_path=/path/to/clang++
```

#### Custom output directory
Generate the file in a specific directory:
```bash
premake5 export-compile-commands --out_dir=.vscode
```
