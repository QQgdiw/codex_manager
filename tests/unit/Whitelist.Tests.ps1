$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$tomlLibrary = Join-Path $projectRoot 'scripts\lib\Read-Toml.ps1'
$fixtures = Join-Path $projectRoot 'tests\fixtures'

function New-ValidWhitelistTool {
    return @{
        id = 'skill.example'
        name = 'Example Skill'
        type = 'skill'
        source = 'https://github.com/example/example-skill'
        version = 'v1.0.0'
        sha256 = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef'
        license = 'MIT'
        approval = 'proposed'
        risk = 'low'
        install_target = 'Skills/example-skill'
        credential_refs = @()
        conflicts = @()
    }
}

Describe 'Test-WhitelistDocument' {
    BeforeAll {
        . $tomlLibrary
    }

    It 'accepts a valid whitelist' {
        $document = Read-ProjectToml -Path (Join-Path $fixtures 'whitelist.valid.toml')
        $result = Test-WhitelistDocument -Document $document

        $result.IsValid | Should Be $true
        $result.Errors.Count | Should Be 0
        $null -eq $result.Warnings | Should Be $false
    }

    It 'accepts the empty initial whitelist without inventing approved tools' {
        $document = Read-ProjectToml -Path (Join-Path $projectRoot 'Resources\tool_whitelist.toml')
        $result = Test-WhitelistDocument -Document $document

        $result.IsValid | Should Be $true
        $document.tools.Count | Should Be 0
    }

    It 'returns all ordinary field errors instead of throwing' {
        $document = Read-ProjectToml -Path (Join-Path $fixtures 'whitelist.invalid.toml')
        $result = $null

        { $script:result = Test-WhitelistDocument -Document $document } | Should Not Throw
        $script:result.IsValid | Should Be $false
        ($script:result.Errors -join "`n") | Should Match 'source'
        ($script:result.Errors -join "`n") | Should Match 'version'
        ($script:result.Errors -join "`n") | Should Match 'license'
        ($script:result.Errors -join "`n") | Should Match 'risk'
        ($script:result.Errors -join "`n") | Should Match 'install_target'
        ($script:result.Errors -join "`n") | Should Match 'credential_refs'
        ($script:result.Errors -join "`n") | Should Match 'conflicts'
        ($script:result.Errors -join "`n") | Should Match 'type'
        ($script:result.Errors -join "`n") | Should Match 'approval'
        ($script:result.Errors -join "`n") | Should Match 'sha256'
        ($script:result.Errors -join "`n") | Should Match 'duplicate'
    }

    It 'rejects an empty ID' {
        $document = Read-ProjectToml -Path (Join-Path $fixtures 'whitelist.valid.toml')
        $document.tools[0].id = ''

        $result = Test-WhitelistDocument -Document $document

        $result.IsValid | Should Be $false
        ($result.Errors -join "`n") | Should Match 'id'
    }

    It 'supports Hashtable roots and Hashtable tool entries' {
        $document = @{
            schema_version = '1.0'
            tools = @(New-ValidWhitelistTool)
        }

        $result = Test-WhitelistDocument -Document $document

        $result.IsValid | Should Be $true
        $result.Errors.Count | Should Be 0
    }

    It 'rejects missing, non-string, and unsupported schema versions without throwing' {
        $missing = @{ tools = @() }
        $empty = @{ schema_version = ' '; tools = @() }
        $numeric = @{ schema_version = 1; tools = @() }
        $unsupported = @{ schema_version = '2.0'; tools = @() }

        $missingResult = Test-WhitelistDocument -Document $missing
        $emptyResult = Test-WhitelistDocument -Document $empty
        $numericResult = Test-WhitelistDocument -Document $numeric
        $unsupportedResult = Test-WhitelistDocument -Document $unsupported

        ($missingResult.Errors -join "`n") | Should Match 'schema_version'
        ($emptyResult.Errors -join "`n") | Should Match 'schema_version.*non-empty string'
        ($numericResult.Errors -join "`n") | Should Match 'schema_version.*string'
        ($unsupportedResult.Errors -join "`n") | Should Match 'schema_version.*1.0'
    }

    It 'rejects non-string and empty scalar fields without throwing' {
        $tool = New-ValidWhitelistTool
        $tool.id = 7
        $tool.name = @{}
        $tool.type = ''
        $tool.source = 42
        $tool.version = $null
        $tool.sha256 = @()
        $tool.license = ' '
        $tool.approval = 1
        $tool.risk = @{}
        $tool.install_target = ''
        $document = @{ schema_version = '1.0'; tools = @($tool) }

        $result = $null
        { $script:result = Test-WhitelistDocument -Document $document } | Should Not Throw
        $messages = $script:result.Errors -join "`n"

        foreach ($field in @(
            'id', 'name', 'type', 'source', 'version', 'sha256',
            'license', 'approval', 'risk', 'install_target'
        )) {
            $messages | Should Match ("field '{0}'.*non-empty string" -f $field)
        }
    }

    It 'rejects scalar and invalid-element reference arrays without throwing' {
        $tool = New-ValidWhitelistTool
        $tool.credential_refs = 'TOKEN'
        $tool.conflicts = @('valid.id', '', 42, @{})
        $document = @{ schema_version = '1.0'; tools = @($tool) }

        $result = Test-WhitelistDocument -Document $document
        $messages = $result.Errors -join "`n"

        $messages | Should Match "credential_refs.*array"
        $messages | Should Match "conflicts\[1\].*non-empty string"
        $messages | Should Match "conflicts\[2\].*non-empty string"
        $messages | Should Match "conflicts\[3\].*non-empty string"
    }

    It 'throws only when the document structure is fundamentally unreadable' {
        $nullMessage = try {
            Test-WhitelistDocument -Document $null
            $null
        }
        catch {
            $_.Exception.Message
        }
        $stringMessage = try {
            Test-WhitelistDocument -Document 'not-an-object'
            $null
        }
        catch {
            $_.Exception.Message
        }

        $nullMessage | Should Match 'readable object'
        $stringMessage | Should Match 'readable object'
    }
}
