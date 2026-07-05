# Json

Json is a PowerShell module for importing, formatting, and exporting JSON data in scripts and automation workflows.

## Prerequisites

- PowerShell with `Microsoft.PowerShell.PSResourceGet` available for `Install-PSResource`.
- The [PSModule framework](https://github.com/PSModule) is used for building, testing, and publishing the module.

## Installation

Install the module from the PowerShell Gallery:

```powershell
Install-PSResource -Name Json
Import-Module -Name Json
```

## Commands

- `Import-Json` reads JSON files and converts them to PowerShell objects. Wildcards and pipeline input are supported.
- `Format-Json` formats JSON strings or PowerShell objects as indented or compact JSON.
- `Export-Json` writes PowerShell objects or JSON strings to files, with support for indentation, encoding, `-Force`, and `-PassThru`.

## Usage

Format a JSON string with two-space indentation:

```powershell
Format-Json -JsonString '{"name":"Marius","roles":["admin","dev"]}' -IndentationType Spaces -IndentationSize 2
```

Convert a PowerShell object to compact JSON:

```powershell
@{
	name = 'Marius'
	roles = @('admin', 'dev')
} | Format-Json -Compact
```

Import one or more JSON files:

```powershell
Import-Json -Path 'config.json'
'settings.json', 'users.json' | Import-Json
```

Export an object to a JSON file:

```powershell
$config = @{
	database = @{ host = 'localhost'; port = 5432 }
	logging = @{ level = 'info' }
}

Export-Json -InputObject $config -Path 'config.json' -Depth 4 -Force
```

## Examples

More usage examples are available in the [examples](examples) folder.

You can also inspect the available commands and built-in help from PowerShell:

```powershell
Get-Command -Module Json
Get-Help Format-Json -Examples
```

## Documentation

Command documentation is published at [psmodule.io/Json](https://psmodule.io/Json/).

## Contributing

Issues and pull requests are welcome. Please use the repository issue tracker to report bugs, request features, or discuss improvements.
