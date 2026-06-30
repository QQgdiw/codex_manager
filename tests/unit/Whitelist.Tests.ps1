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

function New-ValidMcpSmokeProfile {
    param([switch]$AsCustomObject)

    $profile = [ordered]@{
        tool_name = 'test-tool'
        timeout_seconds = 10
        expected_content_types = @('text')
        script_path = 'scripts/smoke/mcp/test.mjs'
        script_sha256 = ('a' * 64)
        arguments = [ordered]@{ value = 'approved' }
    }
    if ($AsCustomObject) {
        return [pscustomobject]$profile
    }
    return $profile
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

    It 'accepts the project whitelist with the user-approved baseline' {
        $document = Read-ProjectToml -Path (Join-Path $projectRoot 'Resources\tool_whitelist.toml')
        $result = Test-WhitelistDocument -Document $document

        $result.IsValid | Should Be $true
        $approvedIds = @(
            $document.tools |
                Where-Object { $_.approval -eq 'approved' } |
                ForEach-Object { $_.id }
        )
        @($approvedIds).Count | Should Be 6
        ($approvedIds -contains 'plugin.openai-bundled.browser') | Should Be $true
        ($approvedIds -contains 'plugin.openai-curated.superpowers') | Should Be $true
        ($approvedIds -contains 'mcp.modelcontextprotocol.filesystem') |
            Should Be $true
        ($approvedIds -contains 'mcp.modelcontextprotocol.sequential-thinking') |
            Should Be $true
        ($approvedIds -contains 'skill.context-engineering.context-fundamentals') |
            Should Be $true
        ($approvedIds -contains 'skill.context-engineering.filesystem-context') |
            Should Be $true
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

    It 'accepts a bounded MCP smoke profile' {
        $tool = New-ValidWhitelistTool
        $tool.type = 'mcp'
        $tool.smoke = New-ValidMcpSmokeProfile
        $document = @{ schema_version = '1.0'; tools = @($tool) }

        (Test-WhitelistDocument -Document $document).IsValid | Should Be $true
    }

    It 'accepts a smoke profile parsed from TOML as a PSCustomObject' {
        $document = Read-ProjectToml -Path (
            Join-Path $fixtures 'whitelist.smoke.valid.toml'
        )

        ($document.tools[0].smoke -is [System.Management.Automation.PSCustomObject]) |
            Should Be $true
        (Test-WhitelistDocument -Document $document).IsValid | Should Be $true
    }

    It 'rejects a malformed PSCustomObject smoke profile parsed from TOML' {
        $document = Read-ProjectToml -Path (
            Join-Path $fixtures 'whitelist.smoke.valid.toml'
        )
        $document.tools[0].smoke.timeout_seconds = 0

        $result = Test-WhitelistDocument -Document $document

        $result.IsValid | Should Be $false
        ($result.Errors -join '; ') | Should Match '1 and 30'
    }

    It 'treats uppercase MCP type the same as lowercase mcp' {
        $tool = New-ValidWhitelistTool
        $tool.type = 'MCP'
        $tool.smoke = New-ValidMcpSmokeProfile -AsCustomObject

        $result = Test-WhitelistDocument -Document @{
            schema_version = '1.0'; tools = @($tool)
        }

        $result.IsValid | Should Be $true
    }

    It 'rejects a non-object smoke profile' {
        foreach ($value in @('invalid', 42)) {
            $tool = New-ValidWhitelistTool
            $tool.type = 'mcp'
            $tool.smoke = $value

            $result = Test-WhitelistDocument -Document @{
                schema_version = '1.0'; tools = @($tool)
            }

            $result.IsValid | Should Be $false
            ($result.Errors -join '; ') | Should Match 'smoke must be an object'
        }
    }

    It 'rejects missing smoke fields without duplicate format errors' {
        foreach ($field in @(
            'tool_name', 'timeout_seconds', 'expected_content_types',
            'script_path', 'script_sha256', 'arguments'
        )) {
            $tool = New-ValidWhitelistTool
            $tool.type = 'mcp'
            $tool.smoke = New-ValidMcpSmokeProfile
            $tool.smoke.Remove($field)

            $result = Test-WhitelistDocument -Document @{
                schema_version = '1.0'; tools = @($tool)
            }
            $fieldErrors = @($result.Errors | Where-Object {
                $_ -match [regex]::Escape("field '$field'")
            })

            $result.IsValid | Should Be $false
            $fieldErrors.Count | Should Be 1
        }
    }

    It 'rejects smoke field type errors' {
        $cases = @(
            @{ Field = 'tool_name'; Value = 42; Match = 'non-empty string' },
            @{ Field = 'timeout_seconds'; Value = '10'; Match = 'integer' },
            @{ Field = 'expected_content_types'; Value = 'text'; Match = 'array' },
            @{ Field = 'script_path'; Value = 42; Match = 'non-empty string' },
            @{ Field = 'script_sha256'; Value = 42; Match = 'non-empty string' }
        )
        foreach ($case in $cases) {
            $tool = New-ValidWhitelistTool
            $tool.type = 'mcp'
            $tool.smoke = New-ValidMcpSmokeProfile -AsCustomObject
            $tool.smoke.($case.Field) = $case.Value

            $result = Test-WhitelistDocument -Document @{
                schema_version = '1.0'; tools = @($tool)
            }

            $result.IsValid | Should Be $false
            ($result.Errors -join '; ') | Should Match $case.Match
            if (@('script_path', 'script_sha256') -contains $case.Field) {
                @($result.Errors | Where-Object {
                    $_ -match [regex]::Escape("field '$($case.Field)'")
                }).Count | Should Be 1
            }
        }
    }

    It 'rejects invalid expected content type elements' {
        $tool = New-ValidWhitelistTool
        $tool.type = 'mcp'
        $tool.smoke = New-ValidMcpSmokeProfile
        $tool.smoke.expected_content_types = @('text', 42, '')

        $result = Test-WhitelistDocument -Document @{
            schema_version = '1.0'; tools = @($tool)
        }

        $result.IsValid | Should Be $false
        ($result.Errors -join '; ') | Should Match 'non-empty strings'
    }

    It 'rejects non-object smoke arguments' {
        $tool = New-ValidWhitelistTool
        $tool.type = 'mcp'
        $tool.smoke = New-ValidMcpSmokeProfile -AsCustomObject
        $tool.smoke.arguments = @('invalid')

        $result = Test-WhitelistDocument -Document @{
            schema_version = '1.0'; tools = @($tool)
        }

        $result.IsValid | Should Be $false
        ($result.Errors -join '; ') | Should Match 'arguments.*object'
    }

    It 'rejects smoke profiles on non-MCP tools' {
        $tool = New-ValidWhitelistTool
        $tool.smoke = New-ValidMcpSmokeProfile

        $result = Test-WhitelistDocument -Document @{
            schema_version = '1.0'; tools = @($tool)
        }

        $result.IsValid | Should Be $false
        ($result.Errors -join '; ') | Should Match 'supported only for mcp tools'
    }

    It 'rejects unsafe or malformed MCP smoke profiles' {
        $cases = @(
            @{ Field = 'unknown'; Value = 'value'; Match = 'unknown' },
            @{ Field = 'timeout_seconds'; Value = 0; Match = '1 and 30' },
            @{ Field = 'timeout_seconds'; Value = 31; Match = '1 and 30' },
            @{ Field = 'expected_content_types'; Value = @(); Match = 'non-empty array' },
            @{ Field = 'script_path'; Value = '..\unsafe.mjs'; Match = 'scripts/smoke/mcp' },
            @{ Field = 'script_path'; Value = 'scripts/smoke/mcp/test.ps1'; Match = '.mjs' },
            @{ Field = 'script_sha256'; Value = 'BAD'; Match = '64 lowercase' }
        )
        foreach ($case in $cases) {
            $tool = New-ValidWhitelistTool
            $tool.type = 'mcp'
            $tool.smoke = New-ValidMcpSmokeProfile
            $tool.smoke[$case.Field] = $case.Value
            $result = Test-WhitelistDocument -Document @{
                schema_version = '1.0'; tools = @($tool)
            }
            $result.IsValid | Should Be $false
            ($result.Errors -join '; ') | Should Match $case.Match
        }
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
