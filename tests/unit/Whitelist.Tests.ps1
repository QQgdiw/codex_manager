$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$tomlLibrary = Join-Path $projectRoot 'scripts\lib\Read-Toml.ps1'
$fixtures = Join-Path $projectRoot 'tests\fixtures'

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

    It 'throws only when the document structure is fundamentally unreadable' {
        { Test-WhitelistDocument -Document $null } | Should Throw
        { Test-WhitelistDocument -Document 'not-an-object' } | Should Throw
    }
}
