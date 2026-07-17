# Message form (email)

About / research / blog 페이지 하단의 **Send a message** 폼입니다.  
방문자가 이름·회신 이메일·내용을 보내면 [FormSubmit](https://formsubmit.co)이 `site.email`(`chi0412@snu.ac.kr`)로 전달합니다.

## 첫 사용 (중요)

1. 사이트에서 테스트로 한 번 **Send email**
2. FormSubmit이 **당신의 메일함**으로 확인(activation) 메일을 보냄
3. 메일 안 링크를 클릭해야 이후 메시지가 실제로 수신

확인 전에는 폼이 “보낸 것처럼” 보여도 수신이 안 될 수 있습니다.

## 끄기

`_config.yml`:

```yaml
feedback:
  enabled: false
```

## 예전 Supabase Like/댓글

더 이상 쓰지 않습니다. `tools/supabase_feedback.sql`은 참고용으로만 남겨 두었고, 사이트에서는 호출하지 않습니다.
