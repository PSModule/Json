#Requires -Modules @{ ModuleName = 'Pester'; RequiredVersion = '5.7.1' }

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Pester grouping syntax: known issue.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingConvertToSecureStringWithPlainText', '',
    Justification = 'Used to create a secure string for testing.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingWriteHost', '',
    Justification = 'Log outputs to GitHub Actions logs.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidLongLines', '',
    Justification = 'Long test descriptions and skip switches'
)]
[CmdletBinding()]
param()

Describe 'Module' {
    Context 'Format-Json' {
        BeforeAll {
            $prettyJson = @'
{
    "Name": "Test",
    "Items": [
        {
            "Id": 1,
            "Value": "One"
        },
        {
            "Id": 2,
            "Value": "Two"
        }
    ],
    "Meta": {
        "Active": true,
        "Count": 2
    }
}
'@

            $compactJson = '{"Name":"Test","Items":[{"Id":1,"Value":"One"},{"Id":2,"Value":"Two"}],"Meta":{"Active":true,"Count":2}}'

            $object = [PSCustomObject]@{
                Name  = 'Test'
                Items = @(
                    [PSCustomObject]@{ Id = 1; Value = 'One' },
                    [PSCustomObject]@{ Id = 2; Value = 'Two' }
                )
                Meta  = [ordered]@{ Active = $true; Count = 2 }
            }

            LogGroup 'Pretty JSON' {
                Write-Host "$prettyJson"
            }
            LogGroup 'Compact JSON' {
                Write-Host "$compactJson"
            }
            LogGroup 'Object' {
                Write-Host "$object"
            }
        }

        It 'Should compact pretty JSON' {
            $result = Format-Json -JsonString $prettyJson -Compact
            LogGroup 'compact from string' {
                Write-Host "$result"
            }
            $result | Should -BeExactly $compactJson
        }
        It 'Should compact object' {
            $result = Format-Json -InputObject $object -Compact
            LogGroup 'compact from object' {
                Write-Host "$result"
            }
            $result | Should -BeExactly $compactJson
        }

        It 'Should reindent JSON string with tabs' {
            $result = Format-Json -JsonString $prettyJson -IndentationType Tabs -IndentationSize 1
            LogGroup 'tabs from string' {
                Write-Host "$result"
            }
            ($result -split "`n") | Where-Object { $_ -match '^\t{3}"Id"' } | Should -Not -BeNullOrEmpty
        }
        It 'Should format object with tabs' {
            $result = Format-Json -InputObject $object -IndentationType Tabs -IndentationSize 1
            LogGroup 'tabs from object' {
                Write-Host "$result"
            }
            ($result -split "`n") | Where-Object { $_ -match '^\t{3}"Id"' } | Should -Not -BeNullOrEmpty
        }

        It 'Should use 2-space indentation' {
            $result = Format-Json -JsonString $compactJson -IndentationType Spaces -IndentationSize 2
            LogGroup 'spaces 2 from string' {
                Write-Host "$result"
            }
            ($result -split "`n") | Where-Object { $_ -match '^ {6}"Id"' } | Should -Not -BeNullOrEmpty
        }
        It 'Should use 4-space indentation from object' {
            $result = Format-Json -InputObject $object -IndentationType Spaces -IndentationSize 4
            LogGroup 'spaces 4 from object' {
                Write-Host "$result"
            }
            ($result -split "`n") | Where-Object { $_ -match '^ {12}"Id"' } | Should -Not -BeNullOrEmpty
        }

        It 'Should throw on invalid input' {
            { Format-Json -JsonString '{ bad json' } | Should -Throw
        }
    }

    Context 'Data Type Handling' {
        It 'Should format null values correctly' {
            $objectWithNull = [PSCustomObject]@{
                Name        = 'Test'
                NullValue   = $null
                EmptyString = ''
            }
            $result = Format-Json -InputObject $objectWithNull -Compact
            LogGroup 'null value formatting' {
                Write-Host "$result"
            }
            $result | Should -Match '"NullValue":null'
            $result | Should -Match '"EmptyString":""'
        }

        It 'Should format decimal numbers correctly' {
            $objectWithDecimals = [PSCustomObject]@{
                Price       = 2.5
                Tax         = 0.125
                Discount    = 10.99
                ZeroDecimal = 0.0
            }
            $result = Format-Json -InputObject $objectWithDecimals -Compact
            LogGroup 'decimal formatting' {
                Write-Host "$result"
            }
            $result | Should -Match '"Price":2\.5'
            $result | Should -Match '"Tax":0\.125'
            $result | Should -Match '"Discount":10\.99'
            $result | Should -Match '"ZeroDecimal":0(\.0)?'
        }

        It 'Should format boolean values correctly' {
            $objectWithBooleans = [PSCustomObject]@{
                IsActive  = $true
                IsDeleted = $false
                IsEnabled = $true
            }
            $result = Format-Json -InputObject $objectWithBooleans -Compact
            LogGroup 'boolean formatting' {
                Write-Host "$result"
            }
            $result | Should -Match '"IsActive":true'
            $result | Should -Match '"IsDeleted":false'
            $result | Should -Match '"IsEnabled":true'
        }

        It 'Should format integer numbers correctly' {
            $objectWithIntegers = [PSCustomObject]@{
                Count       = 42
                Zero        = 0
                Negative    = -15
                LargeNumber = 1000000
            }
            $result = Format-Json -InputObject $objectWithIntegers -Compact
            LogGroup 'integer formatting' {
                Write-Host "$result"
            }
            $result | Should -Match '"Count":42'
            $result | Should -Match '"Zero":0'
            $result | Should -Match '"Negative":-15'
            $result | Should -Match '"LargeNumber":1000000'
        }

        It 'Should format arrays with mixed data types' {
            $objectWithMixedArray = [PSCustomObject]@{
                MixedArray = @(
                    'string',
                    42,
                    2.5,
                    $true,
                    $false,
                    $null
                )
            }
            $result = Format-Json -InputObject $objectWithMixedArray -Compact
            LogGroup 'mixed array formatting' {
                Write-Host "$result"
            }
            $result | Should -Match '"MixedArray":\["string",42,2\.5,true,false,null\]'
        }

        It 'Should format empty collections correctly' {
            $objectWithEmptyCollections = [PSCustomObject]@{
                EmptyArray  = @()
                EmptyObject = @{}
            }
            $result = Format-Json -InputObject $objectWithEmptyCollections -Compact
            LogGroup 'empty collections formatting' {
                Write-Host "$result"
            }
            $result | Should -Match '"EmptyArray":\[\]'
            $result | Should -Match '"EmptyObject":\{\}'
        }

        It 'Should format nested objects with various data types' {
            $complexObject = [PSCustomObject]@{
                User = [PSCustomObject]@{
                    Name      = 'John Doe'
                    Age       = 30
                    Height    = 5.9
                    IsActive  = $true
                    LastLogin = $null
                    Roles     = @('admin', 'user')
                    Settings  = [ordered]@{
                        Theme         = 'dark'
                        Notifications = $false
                        MaxItems      = 100
                    }
                }
            }
            $result = Format-Json -InputObject $complexObject -IndentationType Spaces -IndentationSize 2
            LogGroup 'complex nested object formatting' {
                Write-Host "$result"
            }
            $result | Should -Match '"Name": "John Doe"'
            $result | Should -Match '"Age": 30'
            $result | Should -Match '"Height": 5\.9'
            $result | Should -Match '"IsActive": true'
            $result | Should -Match '"LastLogin": null'
            $result | Should -Match '"Notifications": false'
        }
    }

    Context 'Complex JSON Structures' {
        It 'Should format JSON Schema-like structures' {
            # JSON Schema is a common complex structure used for validation
            $jsonSchema = [PSCustomObject]@{
                '$schema'  = 'https://json-schema.org/draft/2020-12/schema'
                '$id'      = 'https://example.com/person.schema.json'
                title      = 'Person'
                type       = 'object'
                properties = [ordered]@{
                    firstName = [ordered]@{
                        type        = 'string'
                        description = 'The person''s first name.'
                    }
                    lastName  = [ordered]@{
                        type        = 'string'
                        description = 'The person''s last name.'
                    }
                    age       = [ordered]@{
                        type        = 'integer'
                        description = 'Age in years which must be equal to or greater than zero.'
                        minimum     = 0
                    }
                }
                required   = @('firstName', 'lastName')
            }
            $result = Format-Json -InputObject $jsonSchema -IndentationType Spaces -IndentationSize 2
            LogGroup 'JSON Schema formatting' {
                Write-Host "$result"
            }
            $result | Should -Match '"\$schema":'
            $result | Should -Match '"properties":'
            $result | Should -Match '"required": \['
        }

        It 'Should format deeply nested objects (10+ levels)' {
            # Test deep nesting which can occur in configuration files
            $deepNested = [PSCustomObject]@{
                level1 = @{
                    level2 = @{
                        level3 = @{
                            level4 = @{
                                level5 = @{
                                    level6 = @{
                                        level7 = @{
                                            level8 = @{
                                                level9 = @{
                                                    level10 = [ordered]@{
                                                        deepValue = 'Found me!'
                                                        deepArray = @(1, 2, 3)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            $result = Format-Json -InputObject $deepNested -IndentationType Spaces -IndentationSize 2
            LogGroup 'deep nesting formatting' {
                Write-Host "$result"
            }
            $result | Should -Match '"deepValue": "Found me!"'
            # Check that indentation is working at deep levels (deepValue should be at level 11 = 22 spaces with 2-space indentation)
            $result | Should -Match '(?m)^ {22}"deepValue":'
        }

        It 'Should format API response-like structures' {
            # Common REST API response structure
            $apiResponse = [PSCustomObject]@{
                status = 'success'
                data   = @{
                    users = @(
                        [ordered]@{
                            id          = 1
                            name        = 'Alice'
                            email       = 'alice@example.com'
                            profile     = [ordered]@{
                                avatar = 'https://example.com/avatar1.jpg'
                                bio    = 'Software developer'
                                social = [ordered]@{
                                    twitter = '@alice'
                                    github  = 'alice-dev'
                                }
                            }
                            permissions = @('read', 'write', 'admin')
                        },
                        [ordered]@{
                            id          = 2
                            name        = 'Bob'
                            email       = 'bob@example.com'
                            profile     = [ordered]@{
                                avatar = $null
                                bio    = ''
                                social = @{}
                            }
                            permissions = @('read')
                        }
                    )
                }
                meta   = [ordered]@{
                    total    = 2
                    page     = 1
                    per_page = 10
                    has_more = $false
                }
                links  = [ordered]@{
                    self = 'https://api.example.com/users?page=1'
                    next = $null
                    prev = $null
                }
            }
            $result = Format-Json -InputObject $apiResponse -IndentationType Spaces -IndentationSize 2
            LogGroup 'API response formatting' {
                Write-Host "$result"
            }
            $result | Should -Match '"status": "success"'
            $result | Should -Match '"permissions": \['
            $result | Should -Match '"has_more": false'
            $result | Should -Match '"next": null'
        }

        It 'Should format configuration file-like structures' {
            # Complex configuration with various data types
            $configuration = [PSCustomObject]@{
                version     = '2.1'
                environment = 'production'
                database    = [ordered]@{
                    connections = [ordered]@{
                        primary  = [ordered]@{
                            host     = 'db1.example.com'
                            port     = 5432
                            database = 'myapp'
                            ssl      = $true
                            pool     = [ordered]@{
                                min          = 5
                                max          = 20
                                idle_timeout = 30000
                            }
                        }
                        readonly = [ordered]@{
                            host     = 'db2.example.com'
                            port     = 5432
                            database = 'myapp'
                            ssl      = $true
                        }
                    }
                }
                cache       = @{
                    redis = [ordered]@{
                        cluster = @(
                            [ordered]@{ host = 'redis1.example.com'; port = 6379 },
                            [ordered]@{ host = 'redis2.example.com'; port = 6379 },
                            [ordered]@{ host = 'redis3.example.com'; port = 6379 }
                        )
                        ttl     = 3600
                    }
                }
                features    = [ordered]@{
                    feature_flags = [ordered]@{
                        new_ui    = $true
                        beta_api  = $false
                        analytics = $true
                    }
                    rate_limiting = [ordered]@{
                        enabled             = $true
                        requests_per_minute = 1000
                        burst_limit         = 1500
                    }
                }
                monitoring  = [ordered]@{
                    metrics = [ordered]@{
                        enabled  = $true
                        endpoint = 'https://metrics.example.com'
                        interval = 60
                    }
                    logging = [ordered]@{
                        level        = 'info'
                        destinations = @('console', 'file', 'syslog')
                        structured   = $true
                    }
                }
            }
            $result = Format-Json -InputObject $configuration -IndentationType Spaces -IndentationSize 2
            LogGroup 'configuration formatting' {
                Write-Host "$result"
            }
            $result | Should -Match '"version": "2\.1"'
            $result | Should -Match '"cluster": \['
            $result | Should -Match '"requests_per_minute": 1000'
            $result | Should -Match '"destinations": \['
        }

        It 'Should format arrays of objects with varying properties' {
            # Real-world scenario where objects in an array have different properties
            $mixedObjectArray = [PSCustomObject]@{
                events = @(
                    [ordered]@{
                        type       = 'user_login'
                        timestamp  = '2023-01-01T10:00:00Z'
                        user_id    = 123
                        ip_address = '192.168.1.1'
                    },
                    [ordered]@{
                        type       = 'purchase'
                        timestamp  = '2023-01-01T11:30:00Z'
                        user_id    = 123
                        product_id = 'ABC123'
                        amount     = 29.99
                        currency   = 'USD'
                    },
                    [ordered]@{
                        type        = 'error'
                        timestamp   = '2023-01-01T12:00:00Z'
                        error_code  = 500
                        message     = 'Internal server error'
                        stack_trace = $null
                        context     = [ordered]@{
                            request_id = 'req-456'
                            user_agent = 'Mozilla/5.0...'
                        }
                    }
                )
            }
            $result = Format-Json -InputObject $mixedObjectArray -IndentationType Spaces -IndentationSize 2
            LogGroup 'mixed object array formatting' {
                Write-Host "$result"
            }
            $result | Should -Match '"type": "user_login"'
            $result | Should -Match '"amount": 29\.99'
            $result | Should -Match '"error_code": 500'
            $result | Should -Match '"stack_trace": null'
        }

        It 'Should handle special characters and Unicode in strings' {
            # Test various special characters that need escaping or careful handling
            $specialCharacters = [PSCustomObject]@{
                quotes          = 'He said "Hello World"'
                backslashes     = 'C:\Windows\System32'
                newlines        = "Line 1`nLine 2`nLine 3"
                tabs            = "Column1`tColumn2`tColumn3"
                unicode         = 'Café ñ 中文 🚀 ❤️'
                json_escape     = '{"nested": "json"}'
                empty_string    = ''
                whitespace_only = '   '
            }
            $result = Format-Json -InputObject $specialCharacters -Compact
            LogGroup 'special characters formatting' {
                Write-Host "$result"
            }
            $result | Should -Match '"quotes":"He said \\"Hello World\\""'
            $result | Should -Match '"unicode":"Café ñ 中文 🚀 ❤️"'
            $result | Should -Match '"empty_string":""'
        }
    }

    Context 'Import-Json' {
        BeforeAll {
            # Create test JSON files
            $testDataPath = Join-Path $TestDrive 'testdata'
            New-Item -Path $testDataPath -ItemType Directory -Force | Out-Null

            $simpleJson = @'
{
    "name": "Test User",
    "age": 30,
    "active": true
}
'@
            $simpleJsonPath = Join-Path $testDataPath 'simple.json'
            $simpleJson | Out-File -FilePath $simpleJsonPath -Encoding UTF8

            $complexJson = @'
{
    "users": [
        {
            "id": 1,
            "name": "Alice",
            "settings": {
                "theme": "dark",
                "notifications": true
            }
        },
        {
            "id": 2,
            "name": "Bob",
            "settings": {
                "theme": "light",
                "notifications": false
            }
        }
    ],
    "metadata": {
        "version": "1.0",
        "created": "2023-01-01"
    }
}
'@
            $complexJsonPath = Join-Path $testDataPath 'complex.json'
            $complexJson | Out-File -FilePath $complexJsonPath -Encoding UTF8

            $emptyJsonPath = Join-Path $testDataPath 'empty.json'
            '' | Out-File -FilePath $emptyJsonPath -Encoding UTF8

            $invalidJsonPath = Join-Path $testDataPath 'invalid.json'
            '{ invalid json }' | Out-File -FilePath $invalidJsonPath -Encoding UTF8

            LogGroup 'Test files created' {
                Write-Host "Simple JSON: $simpleJsonPath"
                Write-Host "Complex JSON: $complexJsonPath"
                Write-Host "Empty JSON: $emptyJsonPath"
                Write-Host "Invalid JSON: $invalidJsonPath"
            }
        }

        It 'Should import simple JSON file' {
            $result = Import-Json -Path $simpleJsonPath
            LogGroup 'simple import result' {
                Write-Host "$($result | ConvertTo-Json -Depth 3 -Compress)"
            }
            $result.name | Should -Be 'Test User'
            $result.age | Should -Be 30
            $result.active | Should -Be $true
            $result._SourceFile | Should -Be $simpleJsonPath
        }

        It 'Should import complex JSON file' {
            $result = Import-Json -Path $complexJsonPath
            LogGroup 'complex import result' {
                Write-Host "$($result | ConvertTo-Json -Depth 5 -Compress)"
            }
            $result.users | Should -HaveCount 2
            $result.users[0].name | Should -Be 'Alice'
            $result.users[1].name | Should -Be 'Bob'
            $result.metadata.version | Should -Be '1.0'
            $result._SourceFile | Should -Be $complexJsonPath
        }

        It 'Should import multiple files using wildcards' {
            # Test with only valid JSON files to avoid interference from invalid ones
            $validJsonPath1 = Join-Path $testDataPath 'valid1.json'
            $validJsonPath2 = Join-Path $testDataPath 'valid2.json'

            '{"type":"user","name":"Test User"}' | Out-File -FilePath $validJsonPath1 -Encoding UTF8
            '{"type":"product","name":"Widget"}' | Out-File -FilePath $validJsonPath2 -Encoding UTF8

            $results = Import-Json -Path (Join-Path $testDataPath 'valid*.json')
            LogGroup 'wildcard import results' {
                Write-Host "Found $($results.Count) results"
                $results | ForEach-Object { Write-Host "File: $($_._SourceFile), Type: $($_.type), Name: $($_.name)" }
            }
            $results | Should -HaveCount 2
            ($results | Where-Object { $_.name -eq 'Test User' }) | Should -Not -BeNullOrEmpty
            ($results | Where-Object { $_.name -eq 'Widget' }) | Should -Not -BeNullOrEmpty
        }

        It 'Should support pipeline input' {
            $results = $simpleJsonPath, $complexJsonPath | Import-Json
            LogGroup 'pipeline import results' {
                Write-Host "Pipeline results count: $($results.Count)"
            }
            $results | Should -HaveCount 2
            ($results | Where-Object { $_.name -eq 'Test User' }) | Should -Not -BeNullOrEmpty
            ($results | Where-Object { $_.users -ne $null }) | Should -Not -BeNullOrEmpty
        }

        It 'Should handle non-existent file gracefully' {
            $nonExistentPath = Join-Path $testDataPath 'nonexistent.json'
            { Import-Json -Path $nonExistentPath -ErrorAction Stop } | Should -Throw
        }

        It 'Should handle invalid JSON gracefully' {
            { Import-Json -Path $invalidJsonPath -ErrorAction Stop } | Should -Throw
        }

        It 'Should warn on empty files' {
            $warningMessages = @()
            Import-Json -Path $emptyJsonPath -WarningVariable warningMessages -WarningAction SilentlyContinue
            $warningMessages | Should -Not -BeNullOrEmpty
            $warningMessages[0] | Should -Match 'empty or contains only whitespace'
        }

        It 'Should support custom depth parameter' {
            $result = Import-Json -Path $complexJsonPath -Depth 10
            $result.users | Should -HaveCount 2
            $result.metadata | Should -Not -BeNullOrEmpty
        }

        It 'Should add source file information' {
            $result = Import-Json -Path $simpleJsonPath
            $result._SourceFile | Should -Be $simpleJsonPath
        }

        It 'Should handle relative paths' {
            Push-Location $testDataPath
            try {
                $result = Import-Json -Path 'simple.json'
                $result.name | Should -Be 'Test User'
            } finally {
                Pop-Location
            }
        }
    }

    Context 'Export-Json' {
        BeforeAll {
            # Create test data directory
            $exportTestPath = Join-Path $TestDrive 'exportdata'
            New-Item -Path $exportTestPath -ItemType Directory -Force | Out-Null

            # Test objects
            $simpleObject = [PSCustomObject]@{
                name   = 'Test User'
                age    = 30
                active = $true
            }

            $complexObject = [PSCustomObject]@{
                users    = @(
                    [PSCustomObject]@{
                        id       = 1
                        name     = 'Alice'
                        settings = [ordered]@{
                            theme         = 'dark'
                            notifications = $true
                        }
                    },
                    [PSCustomObject]@{
                        id       = 2
                        name     = 'Bob'
                        settings = [ordered]@{
                            theme         = 'light'
                            notifications = $false
                        }
                    }
                )
                metadata = [ordered]@{
                    version = '1.0'
                    created = '2023-01-01'
                }
            }

            $testJsonString = '{"name":"JSON String","value":123,"enabled":true}'

            LogGroup 'Export test setup complete' {
                Write-Host "Export test path: $exportTestPath"
                Write-Host "Simple object: $($simpleObject | ConvertTo-Json -Compress)"
                Write-Host "Test JSON string: $testJsonString"
            }
        }

        It 'Should export simple object to file' {
            $outputPath = Join-Path $exportTestPath 'simple-export.json'
            $result = Export-Json -InputObject $simpleObject -Path $outputPath
            
            LogGroup 'simple export result' {
                Write-Host "Output path: $($result.FullName)"
                Write-Host "File exists: $(Test-Path $outputPath)"
            }
            
            $result.JsonExported | Should -Be $true
            Test-Path $outputPath | Should -Be $true
            
            # Verify content by re-importing
            $imported = Import-Json -Path $outputPath
            $imported.name | Should -Be 'Test User'
            $imported.age | Should -Be 30
            $imported.active | Should -Be $true
        }

        It 'Should export complex object with custom indentation' {
            $outputPath = Join-Path $exportTestPath 'complex-export.json'
            $result = Export-Json -InputObject $complexObject -Path $outputPath -IndentationType Spaces -IndentationSize 2
            
            Test-Path $outputPath | Should -Be $true
            
            # Verify indentation
            $content = Get-Content $outputPath -Raw
            LogGroup 'complex export content' {
                Write-Host $content
            }
            
            $content | Should -Match '  "users": \['
            
            # Verify content by re-importing
            $imported = Import-Json -Path $outputPath
            $imported.users | Should -HaveCount 2
            $imported.users[0].name | Should -Be 'Alice'
            $imported.metadata.version | Should -Be '1.0'
        }

        It 'Should export JSON string to file' {
            $outputPath = Join-Path $exportTestPath 'string-export.json'
            $result = Export-Json -JsonString $testJsonString -Path $outputPath
            
            Test-Path $outputPath | Should -Be $true
            
            # Verify content
            $imported = Import-Json -Path $outputPath
            $imported.name | Should -Be 'JSON String'
            $imported.value | Should -Be 123
            $imported.enabled | Should -Be $true
        }

        It 'Should export in compact format' {
            $outputPath = Join-Path $exportTestPath 'compact-export.json'
            Export-Json -InputObject $simpleObject -Path $outputPath -Compact
            
            $content = Get-Content $outputPath -Raw
            LogGroup 'compact export content' {
                Write-Host $content
            }
            
            # Should be single line without extra whitespace
            $content.Trim() | Should -Not -Match '\n'
            $content | Should -Match '{"name":"Test User","age":30,"active":true}'
        }

        It 'Should export with tab indentation' {
            $outputPath = Join-Path $exportTestPath 'tab-export.json'
            Export-Json -InputObject $complexObject -Path $outputPath -IndentationType Tabs -IndentationSize 1
            
            $content = Get-Content $outputPath -Raw
            LogGroup 'tab export content' {
                Write-Host $content
            }
            
            # Check for tab indentation - look for tabs in the content
            $content | Should -Match '\t"users": \['
        }

        It 'Should create directory if it does not exist' {
            $nestedPath = Join-Path $exportTestPath 'nested' | Join-Path -ChildPath 'deep' | Join-Path -ChildPath 'output.json'
            Export-Json -InputObject $simpleObject -Path $nestedPath
            
            Test-Path $nestedPath | Should -Be $true
            
            # Verify content
            $imported = Import-Json -Path $nestedPath
            $imported.name | Should -Be 'Test User'
        }

        It 'Should support pipeline input with placeholders' {
            $objects = @($simpleObject, $complexObject)
            $basePath = Join-Path $exportTestPath 'pipeline-{0}.json'
            
            $results = $objects | Export-Json -Path $basePath
            
            $results | Should -HaveCount 2
            
            # Check both files were created
            $file1 = Join-Path $exportTestPath 'pipeline-0.json'
            $file2 = Join-Path $exportTestPath 'pipeline-1.json'
            
            Test-Path $file1 | Should -Be $true
            Test-Path $file2 | Should -Be $true
            
            # Verify contents
            $imported1 = Import-Json -Path $file1
            $imported2 = Import-Json -Path $file2
            
            $imported1.name | Should -Be 'Test User'
            $imported2.users | Should -HaveCount 2
        }

        It 'Should handle file overwrite with Force parameter' {
            $outputPath = Join-Path $exportTestPath 'overwrite-test.json'
            
            # Create initial file
            Export-Json -InputObject $simpleObject -Path $outputPath
            $initialContent = Get-Content $outputPath -Raw
            
            # Overwrite with different content
            $newObject = [PSCustomObject]@{ updated = $true; timestamp = '2024-01-01' }
            Export-Json -InputObject $newObject -Path $outputPath -Force
            
            $newContent = Get-Content $outputPath -Raw
            $newContent | Should -Not -Be $initialContent
            
            # Verify new content
            $imported = Import-Json -Path $outputPath
            $imported.updated | Should -Be $true
            $imported.timestamp | Should -Be '2024-01-01'
        }

        It 'Should handle different encodings' {
            $outputPath = Join-Path $exportTestPath 'encoding-test.json'
            $objectWithUnicode = [PSCustomObject]@{
                text    = 'Café ñ 中文 🚀'
                symbols = '♠♥♦♣'
            }
            
            Export-Json -InputObject $objectWithUnicode -Path $outputPath -Encoding UTF8
            
            # Verify content can be read back correctly
            $imported = Import-Json -Path $outputPath
            $imported.text | Should -Be 'Café ñ 中文 🚀'
            $imported.symbols | Should -Be '♠♥♦♣'
        }

        It 'Should handle custom depth parameter' {
            $deepObject = [PSCustomObject]@{
                level1 = @{
                    level2 = @{
                        level3 = @{
                            value = 'deep nested value'
                        }
                    }
                }
            }
            
            $outputPath = Join-Path $exportTestPath 'deep-export.json'
            Export-Json -InputObject $deepObject -Path $outputPath -Depth 10
            
            # Verify deep structure is preserved
            $imported = Import-Json -Path $outputPath
            $imported.level1.level2.level3.value | Should -Be 'deep nested value'
        }

        It 'Should handle invalid JSON string gracefully' {
            $outputPath = Join-Path $exportTestPath 'invalid-test.json'
            { Export-Json -JsonString '{ invalid json }' -Path $outputPath -ErrorAction Stop } | Should -Throw
        }

        It 'Should work with WhatIf parameter' {
            $outputPath = Join-Path $exportTestPath 'whatif-test.json'
            Export-Json -InputObject $simpleObject -Path $outputPath -WhatIf
            
            # File should not be created with WhatIf
            Test-Path $outputPath | Should -Be $false
        }

        It 'Should integrate with Import-Json for roundtrip' {
            $outputPath = Join-Path $exportTestPath 'roundtrip-test.json'
            
            # Export then import
            Export-Json -InputObject $complexObject -Path $outputPath -IndentationType Spaces -IndentationSize 2
            $imported = Import-Json -Path $outputPath
            
            # Verify roundtrip integrity
            $imported.users | Should -HaveCount 2
            $imported.users[0].name | Should -Be 'Alice'
            $imported.users[0].settings.theme | Should -Be 'dark'
            $imported.users[1].name | Should -Be 'Bob'
            $imported.users[1].settings.notifications | Should -Be $false
            $imported.metadata.version | Should -Be '1.0'
        }
    }
}
