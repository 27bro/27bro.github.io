# GitHub Pages 배포 가이드 (27bro.github.io)

## 정상 워크플로

1. `website/` 소스 수정
2. (포스터 변경 시) `update_poster.ps1` 실행
3. `git add` → `git commit` → `git push origin main`
4. 배포 확인 (아래 "배포 확인" 참고)

## 포스터 변환

| Target | PPTX | 출력 |
|--------|------|------|
| `wcb` | `202607WCB/2026WCB_ChLee_Fianl.pptx` | `assets/img/poster.png`, `assets/files/poster.pdf` |
| `job` | `202607WCB/2026WCB_JobPoster_CHLee_Final.pptx` | `assets/img/job_poster.png`, `assets/files/job_poster.pdf` |

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\update_poster.ps1 -Target job
```

## push 후 사이트가 안 바뀔 때

### 1. 콘텐츠 vs 배포 분리

```powershell
cd website
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
bundle exec jekyll build --destination C:\Users\LocalCH\jekyll_verify2
```

빌드 HTML에 변경이 있으면 **코드는 정상**. 문제는 GitHub Pages 배포.

### 2. 상태 확인

```powershell
$gh = "C:\Users\LocalCH\Tools\gh\bin\gh.exe"
& $gh api repos/27bro/27bro.github.io/pages/builds/latest --jq "[.status,.commit[0:7]]"
& $gh api repos/27bro/27bro.github.io/pages --jq "{status, build_type}"
& $gh run list --repo 27bro/27bro.github.io --limit 5
```

| 증상 | 의미 |
|------|------|
| `pages/builds/latest` = `building` (오래 지속) | 빌드 stuck, 배포 락 |
| `pages.status` = `errored` | 배포 실패 상태 |
| Actions run `queued` 여러 개 | deadlock — **재시도 반복 금지** |
| deploy 로그 `Deployment failed, try again later.` | GitHub 측 일시 오류 (코드 문제 아님) |

### 3. 해결 — legacy Pages 재빌드

**이 방법이 실제로 deadlock을 풀었다 (2026-07-05).**

```powershell
$gh = "C:\Users\LocalCH\Tools\gh\bin\gh.exe"
& $gh api -X POST repos/27bro/27bro.github.io/pages/builds
Start-Sleep -Seconds 15
& $gh api repos/27bro/27bro.github.io/pages/builds/latest --jq "[.status,.commit[0:7]]"
```

`built`가 아니면 30초 뒤 위 jq 한 줄만 **한 번 더** 확인. 2분 이상 폴링 루프는 하지 말 것 (터미널 로딩·교착 체감 방지).

`built` + 최신 commit SHA 확인 후 라이ve 검증:

```powershell
$r = Invoke-WebRequest -Uri ("https://27bro.github.io/?v=" + (Get-Random)) -UseBasicParsing
$r.Content -match 'postdoctoral position'   # 예: About 페이지 변경 확인
```

### 4. 하지 말 것

- Actions Re-run / 빈 커밋 연속 push → queued run 누적, 더 악화
- `gh run cancel` → stuck re-run은 409로 취소 불가
- deploy 실패만 보고 코드부터 수정

## 로컬 미리보기

```powershell
cd website
bundle exec jekyll serve --destination C:\Users\LocalCH\jekyll_rcil_site --host 127.0.0.1 --port 4000
```

Dropbox 밖 destination 권장. stale 서버 여러 개 떠 있으면 포트 4000 정리 후 하나만 실행.
