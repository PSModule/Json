# JSON Module Examples
# This file contains practical examples of using the Format-Json function

# Import the module (if not already loaded)
# Import-Module Json

#region Basic Examples

# Example 1: Format a simple JSON string with spaces indentation
Write-Host 'Example 1: Format JSON with spaces (default)' -ForegroundColor Green
$jsonString = '{"a":1,"b":{"c":2}}'
$formatted = Format-Json -JsonString $jsonString -IndentationType Spaces -IndentationSize 2
Write-Output $formatted
Write-Host "`n" + '='*50 + "`n"

# Example 2: Format a PowerShell object as JSON with tabs
Write-Host 'Example 2: Format PowerShell object with tabs' -ForegroundColor Green
$obj = @{
    user     = 'Marius'
    roles    = @('admin', 'dev')
    settings = @{
        theme         = 'dark'
        notifications = $true
    }
}
$formatted = Format-Json -InputObject $obj -IndentationType Tabs -IndentationSize 1
Write-Output $formatted
Write-Host "`n" + '='*50 + "`n"

# Example 3: Compact (minified) JSON output
Write-Host 'Example 3: Compact JSON output' -ForegroundColor Green
$jsonString = '{"a":1,"b":{"c":2}}'
$compact = Format-Json -JsonString $jsonString -Compact
Write-Output $compact
Write-Host "`n" + '='*50 + "`n"

#endregion

#region Advanced Examples

# Example 4: Complex nested object with different indentation sizes
Write-Host 'Example 4: Complex nested structure with 4-space indentation' -ForegroundColor Green
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
Write-Output $formatted
Write-Host "`n" + '='*50 + "`n"

# Example 5: Pipeline usage - format multiple JSON strings
Write-Host 'Example 5: Pipeline usage with multiple JSON strings' -ForegroundColor Green
$jsonStrings = @(
    '{"name":"John","age":30}',
    '{"product":"Widget","price":9.99}',
    '{"status":"active","count":42}'
)

$jsonStrings | ForEach-Object {
    Write-Host "Original: $_" -ForegroundColor Yellow
    $formatted = $_ | Format-Json -IndentationType Spaces -IndentationSize 2
    Write-Output $formatted
    Write-Host ''
}
Write-Host '='*50 + "`n"

# Example 6: Error handling demonstration
Write-Host 'Example 6: Error handling with invalid JSON' -ForegroundColor Green
try {
    $invalidJson = '{"invalid": json}'
    Format-Json -JsonString $invalidJson
} catch {
    Write-Warning "Caught expected error: $($_.Exception.Message)"
}
Write-Host "`n" + '='*50 + "`n"

#endregion

#region Practical Use Cases

# Example 7: Format configuration file
Write-Host 'Example 7: Format a configuration file structure' -ForegroundColor Green
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
Write-Output $formatted
Write-Host "`n" + '='*50 + "`n"

# Example 8: Compare compact vs formatted output
Write-Host 'Example 8: Compare compact vs formatted output' -ForegroundColor Green
$data = @{
    items    = @(1, 2, 3, 4, 5)
    metadata = @{ total = 5; page = 1 }
}

Write-Host 'Compact version:' -ForegroundColor Yellow
$compact = Format-Json -InputObject $data -Compact
Write-Output $compact

Write-Host "`nFormatted version:" -ForegroundColor Yellow
$formatted = Format-Json -InputObject $data -IndentationType Spaces -IndentationSize 2
Write-Output $formatted

#endregion

Write-Host "`nAll examples completed!" -ForegroundColor Cyan
