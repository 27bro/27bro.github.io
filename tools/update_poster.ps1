# update_poster.ps1
# 202607WCB 폴더의 PPTX 를 PowerPoint 로 열어 PDF + PNG 로 내보낸 뒤,
# 웹사이트 포스터 자리에 복사합니다.
#
# 사용법 (website 폴더에서):
#   powershell -ExecutionPolicy Bypass -File .\tools\update_poster.ps1              # WCB + Job poster 모두
#   powershell -ExecutionPolicy Bypass -File .\tools\update_poster.ps1 -Target wcb
#   powershell -ExecutionPolicy Bypass -File .\tools\update_poster.ps1 -Target job
#
# PPT 수정 → 이 스크립트 → git push → 배포 확인
# push 후 사이트 미반영 시: tools/DEPLOY.md 참고 (POST /pages/builds 로 재빌드)

param(
    [ValidateSet('wcb', 'job', 'all')]
    [string]$Target = 'all',
    [int]$PngWidth = 1800
)

$ErrorActionPreference = "Stop"

$wcbDir = "C:\Users\LocalCH\Dropbox\Workplace\Git management works\Reward_Free\202607WCB"
$root   = Split-Path -Parent $PSScriptRoot

$Posters = @{
    wcb = @{
        Pptx   = Join-Path $wcbDir "2026WCB_ChLee_Fianl.pptx"
        PngOut = Join-Path $root "assets\img\poster.png"
        PdfOut = Join-Path $root "assets\files\poster.pdf"
        Label  = "10th WCB research poster (Final)"
    }
    job = @{
        Pptx   = Join-Path $wcbDir "2026WCB_JobPoster_CHLee_Final.pptx"
        PngOut = Join-Path $root "assets\img\job_poster.png"
        PdfOut = Join-Path $root "assets\files\job_poster.pdf"
        Label  = "Job market poster (Final)"
    }
}

function Export-Poster {
    param(
        [string]$Pptx,
        [string]$PngOut,
        [string]$PdfOut,
        [string]$Label,
        [int]$PngWidth
    )

    if (-not (Test-Path $Pptx)) { throw "PPTX 를 찾을 수 없습니다: $Pptx" }

    Write-Host ""
    Write-Host "=== $Label ==="
    Write-Host "PPTX  : $Pptx"
    Write-Host "PNG → : $PngOut"
    Write-Host "PDF → : $PdfOut"

    $tmpDir = Join-Path $env:TEMP "poster_export_$(Get-Random)"
    New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null
    $tmpPng = Join-Path $tmpDir "poster.png"
    $tmpPdf = Join-Path $tmpDir "poster.pdf"

    $ppt = New-Object -ComObject PowerPoint.Application
    $pres = $ppt.Presentations.Open($Pptx, $true, $false, $false)

    $pres.SaveAs($tmpPdf, 32)

    $slide = $pres.Slides.Item(1)
    $ratio = $pres.PageSetup.SlideHeight / $pres.PageSetup.SlideWidth
    $pngH  = [int]([math]::Round($PngWidth * $ratio))
    $slide.Export($tmpPng, "PNG", $PngWidth, $pngH)

    $pres.Close()
    $ppt.Quit()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($ppt) | Out-Null

    New-Item -ItemType Directory -Force -Path (Split-Path $PngOut) | Out-Null
    New-Item -ItemType Directory -Force -Path (Split-Path $PdfOut) | Out-Null
    Copy-Item $tmpPng $PngOut -Force
    Copy-Item $tmpPdf $PdfOut -Force
    Remove-Item $tmpDir -Recurse -Force

    Write-Host ("완료 · PNG {0} KB ({1}x{2}), PDF {3} KB" -f `
        [math]::Round((Get-Item $PngOut).Length / 1KB), $PngWidth, $pngH, `
        [math]::Round((Get-Item $PdfOut).Length / 1KB))
}

$targets = if ($Target -eq 'all') { @('wcb', 'job') } else { @($Target) }

foreach ($key in $targets) {
    $p = $Posters[$key]
    Export-Poster -Pptx $p.Pptx -PngOut $p.PngOut -PdfOut $p.PdfOut -Label $p.Label -PngWidth $PngWidth
}

Write-Host ""
Write-Host "모든 포스터 업데이트 완료."
