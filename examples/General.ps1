# JSON Module Examples
# This file contains practical examples of using the Format-Json and Import-Json functions

# Import the module (if not already loaded)
# Import-Module Json

#region Basic Examples

# Example 1: Format a simple JSON string with spaces indentation
'Example 1: Format JSON with spaces (default)'
$jsonString = '{"a":1,"b":{"c":2}}'
$formatted = Format-Json -JsonString $jsonString -IndentationType Spaces -IndentationSize 2
$formatted

# Example 2: Format a PowerShell object as JSON with tabs
'Example 2: Format PowerShell object with tabs'
$obj = @{
    user     = 'Marius'
    roles    = @('admin', 'dev')
    settings = @{
        theme         = 'dark'
        notifications = $true
    }
}
$formatted = Format-Json -InputObject $obj -IndentationType Tabs -IndentationSize 1
$formatted

# Example 3: Compact (minified) JSON output
'Example 3: Compact JSON output'
$jsonString = '{"a":1,"b":{"c":2}}'
$compact = Format-Json -JsonString $jsonString -Compact
$compact

#endregion

#region Advanced Examples

# Example 4: Complex nested object with different indentation sizes
'Example 4: Complex nested structure with 4-space indentation'
$complexObj = @{
    metadata = @{
        version = '1.0.0'
        author  = 'PowerShell Community'
        created = Get-Date -Format 'yyyy-MM-dd'
    }
    data     = @{
        users         = @(
            @{ id = 1; name = 'Alice'; active = $true },
            @{ id = 2; name = 'Bob'; active = $false }
        )
        configuration = @{
            api      = @{
                baseUrl = 'https://api.example.com'
                timeout = 30
                retries = 3
            }
            features = @{
                logging   = $true
                caching   = $false
                analytics = $true
            }
        }
    }
}
$formatted = Format-Json -InputObject $complexObj -IndentationType Spaces -IndentationSize 4
$formatted

# Example 5: Pipeline usage - format multiple JSON strings
'Example 5: Pipeline usage with multiple JSON strings'
$jsonStrings = @(
    '{"name":"John","age":30}',
    '{"product":"Widget","price":9.99}',
    '{"status":"active","count":42}'
)

$jsonStrings | ForEach-Object {
    "Original: $_"
    $formatted = $_ | Format-Json -IndentationType Spaces -IndentationSize 2
    $formatted
    ''
}
('=' * 50 + "`n")

# Example 6: Error handling demonstration
'Example 6: Error handling with invalid JSON'
try {
    $invalidJson = '{"invalid": json}'
    Format-Json -JsonString $invalidJson
} catch {
    Write-Warning "Caught expected error: $($_.Exception.Message)"
}

#endregion

#region Practical Use Cases

# Example 7: Format configuration file
'Example 7: Format a configuration file structure'
$config = @{
    server   = @{
        host = 'localhost'
        port = 8080
        ssl  = @{
            enabled     = $true
            certificate = '/path/to/cert.pem'
            key         = '/path/to/key.pem'
        }
    }
    database = @{
        type = 'postgresql'
        host = 'db.example.com'
        port = 5432
        name = 'myapp'
        pool = @{
            min = 5
            max = 20
        }
    }
    logging  = @{
        level    = 'info'
        file     = '/var/log/app.log'
        rotation = @{
            enabled  = $true
            maxSize  = '100MB'
            maxFiles = 7
        }
    }
}
$formatted = Format-Json -InputObject $config -IndentationType Spaces -IndentationSize 2
$formatted

# Example 8: Compare compact vs formatted output
'Example 8: Compare compact vs formatted output'
$data = @{
    items    = @(1, 2, 3, 4, 5)
    metadata = @{ total = 5; page = 1 }
}

'Compact version:'
$compact = Format-Json -InputObject $data -Compact
$compact

"`nFormatted version:"
$formatted = Format-Json -InputObject $data -IndentationType Spaces -IndentationSize 2
$formatted

#endregion

#endregion

#region Import-Json Examples

# Example 9: Import JSON from a single file
'Example 9: Import JSON from a single file'
# First, create a sample JSON file
$configData = @{
    database = @{
        host = 'localhost'
        port = 5432
        name = 'myapp'
        ssl  = $true
    }
    logging  = @{
        level = 'info'
        file  = '/var/log/app.log'
    }
    features = @{
        caching   = $true
        analytics = $false
    }
}
$configFile = '/tmp/config.json'
$configData | ConvertTo-Json -Depth 3 | Set-Content -Path $configFile

# Import the JSON file
$importedConfig = Import-Json -Path $configFile
$importedConfig
"Database host: $($importedConfig.database.host)"
"Source file: $($importedConfig._SourceFile)"

# Example 10: Import multiple JSON files using wildcards
'Example 10: Import multiple JSON files using wildcards'
# Create multiple JSON files
$userData = @{ name = 'Alice'; role = 'admin'; active = $true }
$settingsData = @{ theme = 'dark'; notifications = $true; language = 'en' }

$userFile = '/tmp/user-data.json'
$settingsFile = '/tmp/user-settings.json'

$userData | ConvertTo-Json | Set-Content -Path $userFile
$settingsData | ConvertTo-Json | Set-Content -Path $settingsFile

# Import all user-*.json files
$allUserData = Import-Json -Path '/tmp/user-*.json'
$allUserData | ForEach-Object {
    "Imported from: $($_._SourceFile)"
    $_ | Format-List
}

# Example 11: Pipeline usage with Import-Json
'Example 11: Pipeline usage with Import-Json'
$jsonFiles = @($configFile, $userFile, $settingsFile)
$allData = $jsonFiles | Import-Json
"Imported $($allData.Count) JSON files via pipeline"

# Example 12: Error handling with Import-Json
'Example 12: Error handling with Import-Json'
try {
    Import-Json -Path '/tmp/nonexistent.json' -ErrorAction Stop
} catch {
    Write-Warning "Caught expected error: $($_.Exception.Message)"
}

# Example 13: Combine Import-Json with Format-Json
'Example 13: Combine Import-Json with Format-Json'
$rawConfig = Import-Json -Path $configFile
$formattedConfig = Format-Json -InputObject $rawConfig -IndentationType Spaces -IndentationSize 2
'Formatted imported configuration:'
$formattedConfig

# Cleanup temporary files
Remove-Item -Path $configFile, $userFile, $settingsFile -ErrorAction SilentlyContinue

#endregion

#region Export-Json Examples

# Example 14: Export simple object to file
'Example 14: Export simple object to file'
$userObject = @{
    name     = 'John Doe'
    age      = 30
    email    = 'john.doe@example.com'
    active   = $true
    roles    = @('user', 'contributor')
}

$outputFile = '/tmp/user-export.json'
Export-Json -InputObject $userObject -Path $outputFile -IndentationType Spaces -IndentationSize 2
'Exported to file:'
Get-Content $outputFile

# Example 15: Export with compact formatting
'Example 15: Export with compact formatting'
$compactFile = '/tmp/user-compact.json'
Export-Json -InputObject $userObject -Path $compactFile -Compact
'Compact export:'
Get-Content $compactFile

# Example 16: Export multiple objects via pipeline
'Example 16: Export multiple objects via pipeline'
$users = @(
    @{ id = 1; name = 'Alice'; department = 'Engineering' },
    @{ id = 2; name = 'Bob'; department = 'Marketing' },
    @{ id = 3; name = 'Carol'; department = 'Sales' }
)

$users | Export-Json -Path '/tmp/user-{0}.json' -IndentationType Tabs -IndentationSize 1
'Pipeline export results:'
Get-ChildItem '/tmp/user-*.json' | ForEach-Object {
    "File: $($_.Name)"
    Get-Content $_.FullName | Select-Object -First 3
    ''
}

# Example 17: Export JSON string to file
'Example 17: Export JSON string to file'
$jsonString = '{"service":"api","version":"1.2.3","endpoints":["/users","/products","/orders"]}'
$serviceFile = '/tmp/service-config.json'
Export-Json -JsonString $jsonString -Path $serviceFile -IndentationType Spaces -IndentationSize 4
'Formatted JSON string export:'
Get-Content $serviceFile

# Example 18: Roundtrip example - Import, modify, export
'Example 18: Roundtrip example - Import, modify, export'
# First create a JSON file to import
$originalConfig = @{
    database = @{
        host = 'localhost'
        port = 5432
        name = 'myapp'
    }
    features = @{
        logging   = $true
        caching   = $false
        analytics = $true
    }
}

$configFile = '/tmp/original-config.json'
Export-Json -InputObject $originalConfig -Path $configFile

# Import and modify
$config = Import-Json -Path $configFile
$config.database.host = 'production-db.example.com'
$config.features.caching = $true
$config.lastModified = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'

# Export the modified configuration
$modifiedFile = '/tmp/modified-config.json'
Export-Json -InputObject $config -Path $modifiedFile -IndentationType Spaces -IndentationSize 2

'Original config:'
Get-Content $configFile
''
'Modified config:'
Get-Content $modifiedFile

# Cleanup temporary files
Remove-Item -Path $outputFile, $compactFile, $serviceFile, $configFile, $modifiedFile, '/tmp/user-*.json' -ErrorAction SilentlyContinue

#endregion

"`nAll examples completed!"
