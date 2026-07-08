# GitHub Pages 배포 가이드 (27bro.github.io)



## 한 줄 요약



```powershell

cd website

# ... 수정, git commit, git push origin main ...

powershell -ExecutionPolicy Bypass -File .\tools\deploy.ps1

```



`deploy.ps1` = Jekyll preflight + `POST /pages/builds` + 짧은 상태 확인.



## 정상 워크플로



1. `website/` 소스 수정

2. (포스터 변경 시) `update_poster.ps1` 실행

3. `git add` → `git commit` → `git push origin main`

4. **`deploy.ps1` 실행** (필수)



## deploy.ps1 옵션



| 옵션 | 용도 |

|------|------|

| (없음) | preflight 빌드 + Pages 재배포 |

| `-PreflightOnly` | push 전 로컬 빌드 검증만 |

| `-SkipPreflight` | 이미 빌드 확인했을 때 배포만 |



## 포스터 변환



| Target | PPTX | 출력 |

|--------|------|------|

| `wcb` | `202607WCB/2026WCB_ChLee_Final.pptx` | `assets/img/poster.png`, `assets/files/poster.pdf` |

| `job` | `202607WCB/2026WCB_JobPoster_CHLee_Final.pptx` | `assets/img/job_poster.png`, `assets/files/job_poster.pdf` |



```powershell

powershell -ExecutionPolicy Bypass -File .\tools\update_poster.ps1 -Target job

```



## push 후 사이트가 안 바뀔 때



### 1. 콘텐츠 vs 배포 분리



```powershell

powershell -ExecutionPolicy Bypass -File .\tools\deploy.ps1 -PreflightOnly

```



실패하면 **마크다운/HTML 문법 문제** — GitHub push 전에 수정.



### 2. 상태 확인



```powershell

$gh = "C:\Users\LocalCH\Tools\gh\bin\gh.exe"

& $gh api repos/27bro/27bro.github.io/pages/builds/latest --jq "[.status,.commit[0:7]]"

& $gh api repos/27bro/27bro.github.io/pages --jq "{status, build_type}"

```



| 증상 | 의미 |

|------|------|

| `pages/builds/latest` = `building` (오래 지속) | 빌드 stuck |

| `pages.status` = `errored` | 배포 실패 — preflight로 원인 분리 후 `deploy.ps1` 재실행 |

| Actions run `queued` 여러 개 | deadlock — **재시도 반복 금지** |



### 3. 하지 말 것



- Actions Re-run / 빈 커밋 연속 push

- 2분 이상 폴링 루프



## 로컬 미리보기



```powershell

bundle exec jekyll serve --destination C:\Users\LocalCH\jekyll_rcil_site --host 127.0.0.1 --port 4000

```



Dropbox 밖 destination 권장.


