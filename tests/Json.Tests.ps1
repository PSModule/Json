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
                    Settings  = @{
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
}
