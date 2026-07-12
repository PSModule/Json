# Json

Json is a PowerShell module for common JSON tasks: pretty-printing or minifying JSON, and reading and writing JSON files as PowerShell objects.

## Installation

Install the module from the PowerShell Gallery:

```powershell
Install-PSResource -Name Json
Import-Module -Name Json
```

## Usage

### Example: Pretty-print a JSON string

Use `Format-Json` to reformat a compact JSON string with readable indentation.

```powershell
Format-Json -JsonString '{"a":1,"b":{"c":2}}' -IndentationType Spaces -IndentationSize 2
```

### Example: Minify a PowerShell object to JSON

Convert an object to compact (minified) JSON.

```powershell
$config = @{ user = 'Marius'; roles = @('admin', 'dev') }
Format-Json -InputObject $config -Compact
```

### Example: Read and write JSON files

Use `Import-Json` to load a file into PowerShell objects and `Export-Json` to write objects back to disk.

```powershell
$settings = Import-Json -Path 'config.json'
$settings.roles += 'reviewer'
Export-Json -InputObject $settings -Path 'config.json' -IndentationType Spaces -IndentationSize 2
```

## Documentation

Documentation is published at [psmodule.io/Json](https://psmodule.io/Json/).

Use PowerShell help and command discovery for module details:

```powershell
Get-Command -Module Json
Get-Help -Name Format-Json -Examples
```
