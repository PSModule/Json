function Import-Json {
    <#
        .SYNOPSIS
        Imports JSON data from a file.

        .DESCRIPTION
        Reads JSON content from one or more files and converts it to PowerShell objects.
        Supports pipeline input for processing multiple files.

        .EXAMPLE
        Import-Json -Path 'config.json'
        
        Imports JSON data from config.json file.

        .EXAMPLE
        Import-Json -Path 'data/*.json'
        
        Imports JSON data from all .json files in the data directory.

        .EXAMPLE
        'settings.json', 'users.json' | Import-Json
        
        Imports JSON data from multiple files via pipeline.

        .EXAMPLE
        Import-Json -Path 'complex.json' -Depth 50
        
        Imports JSON data with a custom maximum depth of 50 levels.

        .LINK
        https://psmodule.io/Json/Functions/Import-Json/
    #>

    [CmdletBinding()]
    param (
        # The path to the JSON file to import. Supports wildcards and multiple paths. Can be provided via pipeline.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [string[]]$Path,

        # The maximum depth to expand nested objects. Default is 100.
        [Parameter()]
        [int]$Depth = 100
    )

    process {
        foreach ($filePath in $Path) {
            try {
                # Resolve wildcards and relative paths
                $resolvedPaths = Resolve-Path -Path $filePath -ErrorAction Stop
                
                foreach ($resolvedPath in $resolvedPaths) {
                    Write-Verbose "Processing file: $($resolvedPath.Path)"
                    
                    # Test if the file exists and is a file (not directory)
                    if (-not (Test-Path -Path $resolvedPath.Path -PathType Leaf)) {
                        Write-Error "File not found or is not a file: $($resolvedPath.Path)"
                        continue
                    }

                    # Read file content
                    $jsonContent = Get-Content -Path $resolvedPath.Path -Raw -ErrorAction Stop
                    
                    # Check if file is empty
                    if ([string]::IsNullOrWhiteSpace($jsonContent)) {
                        Write-Warning "File is empty or contains only whitespace: $($resolvedPath.Path)"
                        continue
                    }

                    # Convert JSON to PowerShell object
                    $jsonObject = $jsonContent | ConvertFrom-Json -Depth $Depth -ErrorAction Stop
                    
                    # Add file path information as a note property for reference
                    if ($jsonObject -is [PSCustomObject]) {
                        Add-Member -InputObject $jsonObject -MemberType NoteProperty -Name '_SourceFile' -Value $resolvedPath.Path -Force
                    }
                    
                    # Output the object
                    $jsonObject
                }
            } catch [System.Management.Automation.ItemNotFoundException] {
                Write-Error "Path not found: $filePath"
            } catch [System.ArgumentException] {
                Write-Error "Invalid JSON format in file: $filePath. $_"
            } catch {
                Write-Error "Failed to import JSON from file '$filePath': $_"
            }
        }
    }
}