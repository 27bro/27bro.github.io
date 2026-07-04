# update_poster.ps1
# 2026WCB 폴더의 PPTX 를 PowerPoint 로 열어 PDF + PNG 로 내보낸 뒤,
# 웹사이트 포스터 자리(assets/img/poster.png, assets/files/poster.pdf)에 복사합니다.
#
# 사용법 (website 폴더에서):
#   powershell -ExecutionPolicy Bypass -File .\tools\update_poster.ps1
#
# PPT 를 수정할 때마다 이 스크립트만 실행하면 홈페이지 포스터가 갱신됩니다.

param(
    [string]$Pptx = "C:\Users\LocalCH\Dropbox\Workplace\Git management works\Reward_Free\2026WCB\2026WCB_ChLee.pptx",
    [int]$PngWidth = 1800
)

$ErrorActionPreference = "Stop"

# 웹사이트 루트(스크립트 위치의 상위 폴더) 기준으로 출력 경로 결정
$root    = Split-Path -Parent $PSScriptRoot
$pngOut  = Join-Path $root "assets\img\poster.png"
$pdfOut  = Join-Path $root "assets\files\poster.pdf"

if (-not (Test-Path $Pptx)) { throw "PPTX 를 찾을 수 없습니다: $Pptx" }

Write-Host "PPTX  : $Pptx"
Write-Host "PNG → : $pngOut"
Write-Host "PDF → : $pdfOut"

# 임시 출력 경로(PowerPoint COM 은 절대경로를 요구)
$tmpDir = Join-Path $env:TEMP "poster_export"
New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null
$tmpPng = Join-Path $tmpDir "poster.png"
$tmpPdf = Join-Path $tmpDir "poster.pdf"

$ppt = New-Object -ComObject PowerPoint.Application
$pres = $ppt.Presentations.Open($Pptx, $true, $false, $false)  # ReadOnly, Untitled, WithWindow=false

# PDF 내보내기 (32 = ppSaveAsPDF)
$pres.SaveAs($tmpPdf, 32)

# 첫 슬라이드를 PNG 로 내보내기 (슬라이드 비율 유지)
$slide  = $pres.Slides.Item(1)
$ratio  = $pres.PageSetup.SlideHeight / $pres.PageSetup.SlideWidth
$pngH   = [int]([math]::Round($PngWidth * $ratio))
$slide.Export($tmpPng, "PNG", $PngWidth, $pngH)

$pres.Close()
$ppt.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($ppt) | Out-Null

# 웹사이트 자리로 복사
New-Item -ItemType Directory -Force -Path (Split-Path $pngOut) | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $pdfOut) | Out-Null
Copy-Item $tmpPng $pngOut -Force
Copy-Item $tmpPdf $pdfOut -Force

Write-Host ""
Write-Host ("완료 · PNG {0} KB ({1}x{2}), PDF {3} KB" -f `
    [math]::Round((Get-Item $pngOut).Length/1KB), $PngWidth, $pngH, `
    [math]::Round((Get-Item $pdfOut).Length/1KB))
