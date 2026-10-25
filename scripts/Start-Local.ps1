[CmdletBinding()]
param([switch]$SkipBuild)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot

function Invoke-LocalDocker {
    param([string[]]$DockerArguments)
    & docker @DockerArguments
    if ($LASTEXITCODE -ne 0) {
        throw "Docker gagal (exit $LASTEXITCODE): $($DockerArguments -join ' ')"
    }
}

Push-Location -LiteralPath $projectRoot
try {
    Invoke-LocalDocker -DockerArguments @('info', '--format', '{{.ServerVersion}}')
    if (-not (Test-Path -LiteralPath 'backend/.env')) {
        Copy-Item -LiteralPath 'backend/.env.example' -Destination 'backend/.env'
    }
    if (-not $SkipBuild) {
        Invoke-LocalDocker -DockerArguments @('compose', 'build', 'api')
    }
    Invoke-LocalDocker -DockerArguments @('compose', 'run', '--rm', '--no-deps', 'api', 'composer', 'install', '--no-interaction', '--prefer-dist')
    if (Select-String -LiteralPath 'backend/.env' -Pattern '^APP_KEY=\s*$' -Quiet) {
        Invoke-LocalDocker -DockerArguments @('compose', 'run', '--rm', '--no-deps', 'api', 'php', 'artisan', 'key:generate', '--force')
    }
    Invoke-LocalDocker -DockerArguments @('compose', 'up', '-d', '--wait', 'postgres', 'mailpit')
    Invoke-LocalDocker -DockerArguments @('compose', 'run', '--rm', '--no-deps', 'api', 'php', 'artisan', 'migrate', '--seed', '--force')
    Invoke-LocalDocker -DockerArguments @('compose', 'run', '--rm', '--no-deps', 'api', 'php', 'artisan', 'storage:link')
    Invoke-LocalDocker -DockerArguments @('compose', 'up', '-d', '--wait', 'api')
    Write-Host 'API: http://127.0.0.1:8000/api/v1/health'
    Write-Host 'Mailpit: http://127.0.0.1:8025'
} finally {
    Pop-Location
}
