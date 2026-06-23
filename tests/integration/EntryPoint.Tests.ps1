$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$entryPoint = Join-Path $projectRoot 'scripts\Invoke-CodexToolManager.ps1'
$journalLibrary = Join-Path $projectRoot 'scripts\lib\ChangeJournal.ps1'

function Write-EntryPointTextFile {
    param(
        [string]$Path,
        [string]$Text
    )

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $encoding = New-Object Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($Path, $Text, $encoding)
}

function New-EntryPointFixture {
    param(
        [string]$Root,
        [string]$Approval = 'approved',
        [string]$ToolId = 'skill.entry',
        [string]$Target = $null
    )

    if ([string]::IsNullOrWhiteSpace($Target)) {
        $Target = Join-Path $Root 'managed\skill.entry'
    }
    $configPath = Join-Path $Root 'config.toml'
    $whitelistPath = Join-Path $Root 'whitelist.toml'
    $hash = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef'
    Write-EntryPointTextFile -Path $configPath -Text @"
schema_version = 1
name = "entrypoint"
enabled_tools = ["$ToolId"]
"@
    Write-EntryPointTextFile -Path $whitelistPath -Text @"
schema_version = "1.0"

[[tools]]
id = "$ToolId"
name = "Entry Point Skill"
type = "skill"
source = "https://example.invalid/entrypoint"
version = "v1.0.0"
sha256 = "$hash"
license = "MIT"
approval = "$Approval"
risk = "low"
install_target = "$($Target.Replace('\', '\\'))"
credential_refs = []
conflicts = []
dependencies = []
permissions = []
external_changes = []
rollback_capability = "managed_files"
"@

    return [pscustomobject]@{
        Config = $configPath
        Whitelist = $whitelistPath
        Target = $Target
    }
}

function Invoke-EntryPointProcess {
    param([string[]]$Arguments)

    $caseRoot = Join-Path $TestDrive ([Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $caseRoot | Out-Null
    $stdout = Join-Path $caseRoot 'stdout.json'
    $stderr = Join-Path $caseRoot 'stderr.txt'
    & powershell -NoProfile -ExecutionPolicy Bypass -File $entryPoint @Arguments `
        > $stdout 2> $stderr
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        StdOutPath = $stdout
        StdErrPath = $stderr
        StdOut = if (Test-Path -LiteralPath $stdout) {
            [IO.File]::ReadAllText($stdout)
        }
        else {
            ''
        }
        StdErr = if (Test-Path -LiteralPath $stderr) {
            [IO.File]::ReadAllText($stderr)
        }
        else {
            ''
        }
    }
}

function ConvertFrom-EntryPointJson {
    param([object]$Run)

    $Run.StdOut.Trim() | Should Not Be ''
    return ($Run.StdOut | ConvertFrom-Json)
}

Describe 'Codex tool manager entry point' {
    It 'plans by default, writes the requested JSON plan, and makes no changes' {
        $fixture = New-EntryPointFixture -Root (Join-Path $TestDrive 'plan')
        $planPath = Join-Path $TestDrive 'plan-output.json'

        $run = Invoke-EntryPointProcess -Arguments @(
            'plan', '-Config', $fixture.Config, '-Whitelist', $fixture.Whitelist,
            '-OutputPath', $planPath
        )

        $run.ExitCode | Should Be 0
        $body = ConvertFrom-EntryPointJson -Run $run
        $body.Command | Should Be 'plan'
        $body.Status | Should Be 'succeeded'
        $body.Plan.Status | Should Be 'planned'
        @($body.Plan.Items).Count | Should Be 1
        (Test-Path -LiteralPath $planPath -PathType Leaf) | Should Be $true
        (Test-Path -LiteralPath $fixture.Target) | Should Be $false
    }

    It 'returns business failure for an unapproved tool without treating it as fatal' {
        $fixture = New-EntryPointFixture -Root (Join-Path $TestDrive 'unapproved') `
            -Approval 'proposed'

        $run = Invoke-EntryPointProcess -Arguments @(
            'plan', '-Config', $fixture.Config, '-Whitelist', $fixture.Whitelist
        )

        $run.ExitCode | Should Be 1
        $body = ConvertFrom-EntryPointJson -Run $run
        $body.Status | Should Be 'blocked'
        (@($body.Plan.Errors) -join "`n") | Should Match 'not approved'
        $run.StdErr.Trim() | Should Be ''
    }

    It 'returns fatal exit code two for invalid configuration input' {
        $root = Join-Path $TestDrive 'fatal'
        New-Item -ItemType Directory -Path $root | Out-Null
        $configPath = Join-Path $root 'bad-config.toml'
        $whitelistPath = Join-Path $root 'whitelist.toml'
        Write-EntryPointTextFile -Path $configPath -Text 'enabled_tools = ['
        $fixture = New-EntryPointFixture -Root $root
        Move-Item -LiteralPath $fixture.Whitelist -Destination $whitelistPath -Force

        $run = Invoke-EntryPointProcess -Arguments @(
            'plan', '-Config', $configPath, '-Whitelist', $whitelistPath
        )

        $run.ExitCode | Should Be 2
        $body = ConvertFrom-EntryPointJson -Run $run
        $body.Status | Should Be 'fatal'
        $body.Message | Should Match 'TOML|converter|config'
    }

    It 'deploy dry-run reports planned work and leaves the target absent' {
        $fixture = New-EntryPointFixture -Root (Join-Path $TestDrive 'dryrun')

        $run = Invoke-EntryPointProcess -Arguments @(
            'deploy', '-Config', $fixture.Config, '-Whitelist', $fixture.Whitelist,
            '-DryRun'
        )

        $run.ExitCode | Should Be 0
        $body = ConvertFrom-EntryPointJson -Run $run
        $body.Command | Should Be 'deploy'
        $body.Status | Should Be 'succeeded'
        @($body.Results)[0].Status | Should Be 'dry_run'
        (Test-Path -LiteralPath $fixture.Target) | Should Be $false
    }

    It 'deploy without an adapter reports blocked business failure' {
        $fixture = New-EntryPointFixture -Root (Join-Path $TestDrive 'deploy-blocked')

        $run = Invoke-EntryPointProcess -Arguments @(
            'deploy', '-Config', $fixture.Config, '-Whitelist', $fixture.Whitelist
        )

        $run.ExitCode | Should Be 1
        $body = ConvertFrom-EntryPointJson -Run $run
        $body.Status | Should Be 'blocked'
        @($body.Results)[0].Status | Should Be 'blocked'
        @($body.Results)[0].Message | Should Match 'adapter'
    }

    It 'verify is conservative when no load or smoke verifier is present' {
        $fixture = New-EntryPointFixture -Root (Join-Path $TestDrive 'verify')

        $run = Invoke-EntryPointProcess -Arguments @(
            'verify', '-Config', $fixture.Config, '-Whitelist', $fixture.Whitelist
        )

        $run.ExitCode | Should Be 1
        $body = ConvertFrom-EntryPointJson -Run $run
        $body.Command | Should Be 'verify'
        $body.Status | Should Be 'blocked'
        @($body.Results | Where-Object { $_.Level -eq 'static' })[0].Status |
            Should Be 'static_verified'
        @($body.Results | Where-Object { $_.Level -eq 'load' })[0].Status |
            Should Be 'blocked'
        @($body.Results | Where-Object { $_.Level -eq 'smoke' })[0].Status |
            Should Be 'blocked'
    }

    It 'credential commands do not print plaintext secrets' {
        $storePath = Join-Path $TestDrive 'credentials\store.dpapi'
        $secret = 'super-secret-entrypoint-value'

        $setRun = Invoke-EntryPointProcess -Arguments @(
            'credential', 'set', '-Name', 'api-token', '-Value', $secret,
            '-StorePath', $storePath
        )
        $getRun = Invoke-EntryPointProcess -Arguments @(
            'credential', 'get', '-Name', 'api-token', '-StorePath', $storePath
        )
        $listRun = Invoke-EntryPointProcess -Arguments @(
            'credential', 'list', '-StorePath', $storePath
        )
        $removeRun = Invoke-EntryPointProcess -Arguments @(
            'credential', 'remove', '-Name', 'api-token', '-StorePath', $storePath
        )

        $setRun.ExitCode | Should Be 0
        $getRun.ExitCode | Should Be 0
        $listRun.ExitCode | Should Be 0
        $removeRun.ExitCode | Should Be 0
        $combined = @(
            $setRun.StdOut, $getRun.StdOut, $listRun.StdOut, $removeRun.StdOut,
            $setRun.StdErr, $getRun.StdErr, $listRun.StdErr, $removeRun.StdErr
        ) -join "`n"
        $combined | Should Not Match ([regex]::Escape($secret))
        (ConvertFrom-EntryPointJson -Run $getRun).Redacted | Should Be $true
        @((ConvertFrom-EntryPointJson -Run $listRun).Credentials).Count |
            Should Be 1
    }

    It 'rollback invokes the change journal rollback path' {
        . $journalLibrary
        $root = Join-Path $TestDrive 'rollback'
        $stateRoot = Join-Path $root '.state'
        $codexRoot = Join-Path $root '.codex-test'
        New-Item -ItemType Directory -Path $root, $codexRoot | Out-Null
        $path = Join-Path $root 'created.txt'
        $journal = New-ChangeJournal `
            -OperationId 'entrypoint-rollback' `
            -AllowedRoots @($root) `
            -CodexRoot $codexRoot `
            -StateRoot $stateRoot
        Add-FileChange -Journal $journal -Path $path -Kind create `
            -AllowedRoots @($root) | Out-Null
        [IO.File]::WriteAllText($path, 'created')
        Confirm-FileChange -Journal $journal -Path $path -AllowedRoots @($root) |
            Out-Null

        $run = Invoke-EntryPointProcess -Arguments @(
            'rollback', '-JournalPath', $journal.JournalPath, '-AllowedRoot', $root
        )

        $run.ExitCode | Should Be 0
        $body = ConvertFrom-EntryPointJson -Run $run
        $body.Status | Should Be 'succeeded'
        $body.Rollback.Status | Should Be 'Succeeded'
        (Test-Path -LiteralPath $path) | Should Be $false
    }

    It 'status reports local inputs without network access' {
        $fixture = New-EntryPointFixture -Root (Join-Path $TestDrive 'status')

        $run = Invoke-EntryPointProcess -Arguments @(
            'status', '-Config', $fixture.Config, '-Whitelist', $fixture.Whitelist
        )

        $run.ExitCode | Should Be 0
        $body = ConvertFrom-EntryPointJson -Run $run
        $body.Command | Should Be 'status'
        $body.Status | Should Be 'succeeded'
        $body.ConfigExists | Should Be $true
        $body.WhitelistExists | Should Be $true
        @($body.AdapterTypes) | Should Be @('plugin', 'mcp', 'skill')
    }
}
