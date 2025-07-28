function Format-Json {
    <#
        .SYNOPSIS
        Formats a JSON string or PowerShell object.

        .DESCRIPTION
        Converts raw JSON strings or PowerShell objects into formatted JSON. Supports
        pretty-printing with configurable indentation or compact output.

        .EXAMPLE
        Format-Json -JsonString '{"a":1,"b":{"c":2}}' -IndentationType Spaces -IndentationSize 2

        .EXAMPLE
        $obj = @{ user = 'Marius'; roles = @('admin','dev') }
        Format-Json -InputObject $obj -IndentationType Tabs -IndentationSize 1

        .EXAMPLE
        Format-Json -JsonString '{"a":1,"b":{"c":2}}' -Compact

        .LINK
        https://psmodule.io/Json/Functions/Format-Json/
    #>

    [CmdletBinding(DefaultParameterSetName = 'FromString')]
    param (
        # JSON string to format.
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'FromString')]
        [string]$JsonString,

        # PowerShell object to convert and format as JSON.
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'FromObject')]
        [PSObject]$InputObject,

        # Produce compact (minified) output.
        [Parameter(ParameterSetName = 'FromString')]
        [Parameter(ParameterSetName = 'FromObject')]
        [switch]$Compact,

        # Indentation type: 'Spaces' or 'Tabs'.
        [Parameter(ParameterSetName = 'FromString')]
        [Parameter(ParameterSetName = 'FromObject')]
        [ValidateSet('Spaces', 'Tabs')]
        [string]$IndentationType = 'Spaces',

        # Number of spaces or tabs per indentation level. Only used if not compacting.
        [Parameter(ParameterSetName = 'FromString')]
        [Parameter(ParameterSetName = 'FromObject')]
        [UInt16]$IndentationSize = 2
    )

    process {
        try {
            $inputObject = if ($PSCmdlet.ParameterSetName -eq 'FromString') {
                $JsonString | ConvertFrom-Json -ErrorAction Stop
            } else {
                $InputObject
            }

            $json = $inputObject | ConvertTo-Json -Depth 100 -Compress:$Compact

            if ($Compact) {
                return $json
            }

            $indentUnit = switch ($IndentationType) {
                'Tabs' { "`t" }
                'Spaces' { ' ' * $IndentationSize }
            }

            $lines = $json -split "`n"
            $level = 0
            $result = foreach ($line in $lines) {
                $trimmed = $line.Trim()
                if ($trimmed -match '^[}\]]') {
                    $level = [Math]::Max(0, $level - 1)
                }
                $indent = $indentUnit * $level
                $indentedLine = "$indent$trimmed"
                # Check if the line ends with an opening bracket ('[' or '{') and is not a closing bracket ('}' or ']') or a comma.
                # This ensures that the indentation level is increased only for lines that introduce a new block.
                if ($trimmed -match '[{\[]$' -and $trimmed -notmatch '^[}\]],?$') {
                    $level++
                }
                $indentedLine
            }

            return ($result -join "`n")
        } catch {
            Write-Error "Failed to format JSON: $_"
        }
    }
}
