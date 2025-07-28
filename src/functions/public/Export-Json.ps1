function Export-Json {
    <#
        .SYNOPSIS
        Exports JSON data to a file.

        .DESCRIPTION
        Converts PowerShell objects to JSON format and writes them to one or more files.
        Supports various formatting options including indentation types, sizes, and compact output.
        Can accept both PowerShell objects and JSON strings as input.

        .EXAMPLE
        Export-Json -InputObject $myObject -Path 'output.json'

        Exports a PowerShell object to output.json with default formatting.

        .EXAMPLE
        Export-Json -InputObject $data -Path 'config.json' -IndentationType Spaces -IndentationSize 2

        Exports data to config.json with 2-space indentation.

        .EXAMPLE
        Export-Json -JsonString $jsonText -Path 'data.json' -Compact

        Exports a JSON string to data.json in compact format.

        .EXAMPLE
        $objects | Export-Json -Path 'output-{0}.json'

        Exports multiple objects to numbered files via pipeline.

        .EXAMPLE
        Export-Json -InputObject $config -Path 'settings.json' -IndentationType Tabs -Force

        Exports configuration to settings.json with tab indentation, overwriting if it exists.

        .LINK
        https://psmodule.io/Json/Functions/Export-Json/
    #>

    [CmdletBinding(DefaultParameterSetName = 'FromObject', SupportsShouldProcess)]
    param (
        # PowerShell object to convert and export as JSON.
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'FromObject')]
        [PSObject]$InputObject,

        # JSON string to export to file.
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'FromString')]
        [string]$JsonString,

        # The path to the output JSON file. Supports placeholders for pipeline processing.
        [Parameter(Mandatory)]
        [string]$Path,

        # Produce compact (minified) output.
        [Parameter()]
        [switch]$Compact,

        # Indentation type: 'Spaces' or 'Tabs'.
        [Parameter()]
        [ValidateSet('Spaces', 'Tabs')]
        [string]$IndentationType = 'Spaces',

        # Number of spaces or tabs per indentation level. Only used if not compacting.
        [Parameter()]
        [UInt16]$IndentationSize = 2,

        # The maximum depth to serialize nested objects.
        [Parameter()]
        [int]$Depth = 2,

        # Overwrite existing files without prompting.
        [Parameter()]
        [switch]$Force,

        # Text encoding for the output file.
        [Parameter()]
        [ValidateSet('ASCII', 'BigEndianUnicode', 'BigEndianUTF32', 'OEM', 'Unicode', 'UTF7', 'UTF8', 'UTF8BOM', 'UTF8NoBOM', 'UTF32')]
        [string]$Encoding = 'UTF8NoBOM'
    )

    begin {
        $fileIndex = 0
    }

    process {
        try {
            # Determine the input object
            $objectToExport = if ($PSCmdlet.ParameterSetName -eq 'FromString') {
                $JsonString | ConvertFrom-Json -Depth $Depth -ErrorAction Stop
            } else {
                $InputObject
            }

            # Generate the file path (support for placeholders in pipeline scenarios)
            $outputPath = if ($Path -match '\{0\}') {
                $Path -f $fileIndex
                $fileIndex++
            } else {
                $Path
            }

            # Resolve the path for consistent operations and error messages
            $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($outputPath)

            # Check if file exists and handle accordingly
            if ((Test-Path -Path $resolvedPath -PathType Leaf) -and -not $Force) {
                if ($PSCmdlet.ShouldProcess($resolvedPath, "Overwrite existing file")) {
                    # Continue with export
                } else {
                    # Only error if not WhatIf - WhatIf should just show what would happen
                    if (-not $WhatIfPreference) {
                        Write-Error "File already exists: $resolvedPath. Use -Force to overwrite."
                    }
                    return
                }
            }

            # Create directory if it doesn't exist
            $directory = Split-Path -Path $resolvedPath -Parent
            if ($directory -and -not (Test-Path -Path $directory -PathType Container)) {
                Write-Verbose "Creating directory: $directory"
                $null = New-Item -Path $directory -ItemType Directory -Force
            }

            # Format the JSON
            if ($Compact) {
                $formattedJson = $objectToExport | ConvertTo-Json -Depth $Depth -Compress
            } else {
                # Use Format-Json for consistent formatting
                $formattedJson = Format-Json -InputObject $objectToExport -IndentationType $IndentationType -IndentationSize $IndentationSize
            }

            # Write to file
            if ($PSCmdlet.ShouldProcess($resolvedPath, "Export JSON")) {
                Write-Verbose "Exporting JSON to: $resolvedPath"

                $writeParams = @{
                    Path     = $resolvedPath
                    Value    = $formattedJson
                    Encoding = $Encoding
                }

                # Only use Force for Set-Content if user explicitly requested it
                if ($Force) {
                    $writeParams['Force'] = $true
                }

                Set-Content @writeParams -ErrorAction Stop

                # Output file info object
                Get-Item -Path $resolvedPath | Add-Member -MemberType NoteProperty -Name 'JsonExported' -Value $true -PassThru
            }
        } catch [System.ArgumentException] {
            Write-Error "Invalid JSON format: $_"
        } catch [System.IO.DirectoryNotFoundException] {
            Write-Error "Directory not found or could not be created: $directory"
        } catch [System.UnauthorizedAccessException] {
            Write-Error "Access denied: $resolvedPath"
        } catch {
            Write-Error "Failed to export JSON to '$resolvedPath': $_"
        }
    }
}