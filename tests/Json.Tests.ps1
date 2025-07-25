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
                Meta  = @{ Active = $true; Count = 2 }
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
}
