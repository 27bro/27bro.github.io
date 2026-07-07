# deploy.ps1 — GitHub Pages(legacy Jekyll) 배포 자동화
#
# website/ 폴더에서:
#   powershell -ExecutionPolicy Bypass -File .\tools\deploy.ps1
#   powershell -ExecutionPolicy Bypass -File .\tools\deploy.ps1 -PreflightOnly
#   powershell -ExecutionPolicy Bypass -File .\tools\deploy.ps1 -SkipPreflight
#
# push 직후 에이전트/사용자가 이 스크립트 하나만 실행하면 됨:
#   1) (기본) jekyll build --safe 로 push 전 빌드 오류 선검출
#   2) POST /pages/builds 로 legacy Pages 재빌드 트리거
#   3) 15s + (필요 시) 30s 후 상태 1~2회만 확인 (긴 폴링 루프 없음)

param(
    [switch]$PreflightOnly,
    [switch]$SkipPreflight,
    [int]$FirstWaitSec = 15,
    [int]$SecondWaitSec = 30
)

$ErrorActionPreference = "Stop"

$gh = "C:\Users\LocalCH\Tools\gh\bin\gh.exe"
if (-not (Test-Path $gh)) { throw "gh not found: $gh" }

$siteRoot = Split-Path -Parent $PSScriptRoot
$dest = Join-Path $env:TEMP ("jekyll_preflight_" + [guid]::NewGuid().ToString("n"))

function Invoke-PreflightBuild {
    Write-Host "=== Jekyll preflight (build --safe) ==="
    Push-Location $siteRoot
    bundle exec jekyll build --safe --destination $dest
    if ($LASTEXITCODE -ne 0) { throw "Jekyll preflight build failed." }
    Pop-Location
    Remove-Item -Recurse -Force $dest -ErrorAction SilentlyContinue
    Write-Host "Preflight OK."
}

function Get-HeadSha {
    Push-Location $siteRoot
    $sha = (git rev-parse HEAD).Trim()
    Pop-Location
    return $sha
}

function Invoke-PagesDeploy {
    $head = Get-HeadSha
    $short = $head.Substring(0, 7)
    Write-Host ""
    Write-Host "=== GitHub Pages deploy (POST /pages/builds) ==="
    Write-Host "Local HEAD: $short"

    & $gh api -X POST repos/27bro/27bro.github.io/pages/builds | Out-Null

    Start-Sleep -Seconds $FirstWaitSec
    $latest = & $gh api repos/27bro/27bro.github.io/pages/builds/latest
    $status = $latest.status
    $commit = $latest.commit
    $commitShort = if ($commit.Length -ge 7) { $commit.Substring(0, 7) } else { $commit }
    Write-Host "After ${FirstWaitSec}s: status=$status commit=$commitShort"

    if ($status -ne "built") {
        Start-Sleep -Seconds $SecondWaitSec
        $latest = & $gh api repos/27bro/27bro.github.io/pages/builds/latest
        $status = $latest.status
        $commit = $latest.commit
        $commitShort = if ($commit.Length -ge 7) { $commit.Substring(0, 7) } else { $commit }
        Write-Host "After $($FirstWaitSec + $SecondWaitSec)s: status=$status commit=$commitShort"
    }

    $pages = & $gh api repos/27bro/27bro.github.io/pages --jq "{status, build_type}"
    Write-Host "Pages site: $pages"

    if ($status -eq "built" -and $commit.StartsWith($head.Substring(0, 7))) {
        Write-Host ""
        Write-Host "Deploy OK: built @ $commitShort"
        Write-Host "Live: https://27bro.github.io/?v=$([guid]::NewGuid().ToString('n').Substring(0,8))"
        return 0
    }

    if ($status -eq "building") {
        Write-Host ""
        Write-Host "Still building — check again in ~1 min:"
        Write-Host "  & `"$gh`" api repos/27bro/27bro.github.io/pages/builds/latest --jq `"[.status,.commit[0:7]]`""
        return 2
    }

    Write-Host ""
    Write-Host "Deploy issue: status=$status commit=$commitShort (expected $short)"
    Write-Host "See website/tools/DEPLOY.md — do NOT spam re-runs or empty commits."
    return 1
}

if (-not $SkipPreflight) {
    Invoke-PreflightBuild
}
if ($PreflightOnly) { exit 0 }

exit (Invoke-PagesDeploy)
