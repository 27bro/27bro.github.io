# RCIL — 학회 홍보용 웹사이트 (Jekyll)

**Referent-Configuration Imitation Learning (RCIL)** 연구 홍보용 Jekyll 사이트입니다.
랜딩 페이지(포스터 + 결과 영상 4칸) + 연구 블로그로 구성돼 있습니다.

> 이 `website/` 폴더는 **자체 완결형**입니다. 나중에 이 폴더 내용만 통째로
> 새 공개 GitHub repo 에 복사하면 GitHub Pages 로 그대로 배포됩니다.
> (연구 코드/데이터는 절대 함께 복사하지 마세요.)

---

## 1. 폴더 구조

```
website/
├─ _config.yml          # 사이트 설정 (제목/저자/링크 등 여기서 수정)
├─ Gemfile              # 로컬 실행용 gem 목록
├─ index.html           # 랜딩 페이지 (포스터/영상 placeholder 포함)
├─ blog.html            # 블로그 목록
├─ _posts/              # 블로그 글 (Markdown)
├─ _layouts/            # 페이지 골격 (default, post)
├─ _includes/           # 공통 조각 (head, nav, footer)
└─ assets/
   ├─ css/style.css     # 디자인
   ├─ img/              # 포스터 이미지·썸네일 (여기에 추가)
   ├─ video/            # 결과 영상(mp4/gif) (여기에 추가)
   └─ files/            # 포스터 PDF 등 다운로드 파일 (여기에 추가)
```

## 2. 로컬에서 미리보기

Ruby 가 필요합니다. (Windows: [RubyInstaller](https://rubyinstaller.org/) 로 Ruby+Devkit 설치)

```powershell
cd website
gem install bundler
bundle install
bundle exec jekyll serve
```

그 다음 브라우저에서 **http://localhost:4000** 접속.
파일을 저장하면 자동으로 다시 빌드됩니다 (`_config.yml` 만 예외 → 서버 재시작 필요).

## 2.5 Send a message (이메일 폼)

About·연구 글 하단에 이름 / 회신 이메일 / 메시지 → 본인 메일로 전송.  
설정: [`tools/FEEDBACK.md`](tools/FEEDBACK.md) (FormSubmit, 무료 · 첫 전송 시 메일 확인 필요)

## 3. 내용 수정하는 법

- **제목/이름/소속/링크**: `_config.yml` 만 고치면 사이트 전체에 반영됩니다.
- **소개 문구**: `index.html` 의 `#about` 섹션.
- **블로그 글 추가**: `_posts/` 에 `YYYY-MM-DD-제목.md` 파일 추가
  (맨 위 front matter 는 `2026-07-03-welcome.md` 참고).

### 포스터 넣기
1. 포스터를 PNG 로 내보내 `assets/img/poster.png` 저장
2. (선택) PDF 를 `assets/files/poster.pdf` 저장
3. `index.html` 의 `#poster` 섹션에서 `▼▼▼ 포스터 넣는 법 ▼▼▼` 주석 안내대로
   `.poster-placeholder` 블록을 실제 `<img>` 로 교체

### 결과 영상 넣기 (4칸)
`index.html` 의 `#results` 섹션 각 칸의 `.video-placeholder` 를,
주석(`▼▼▼ 영상 넣는 법 ▼▼▼`)에 있는 mp4 / gif / YouTube 코드 중 하나로 교체.
- mp4/gif 파일은 `assets/video/` 에 저장
- mp4 파일은 GitHub 파일당 100MB 제한 주의 → 크면 YouTube 임베드 권장

## 4. GitHub Pages 로 배포

1. GitHub 에서 **새 public repo** 생성 (예: `rcil-site`)
2. 이 `website/` 폴더 **안의 내용**을 새 repo 루트로 복사 후 push
3. repo → **Settings → Pages → Source: `Deploy from a branch`** → `main` / `/ (root)` 선택
4. 몇 분 뒤 `https://<username>.github.io/rcil-site/` 에서 확인

> **중요:** 프로젝트 사이트(`.../rcil-site/`)로 배포하면 `_config.yml` 의
> `baseurl` 을 `"/rcil-site"` 로 바꿔야 CSS/링크가 깨지지 않습니다.
> (repo 이름을 `<username>.github.io` 로 만들면 baseurl 은 `""` 그대로 두면 됩니다.)
