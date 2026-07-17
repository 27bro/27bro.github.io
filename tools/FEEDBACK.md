# Feedback (Like + comments)

Free setup with [Supabase](https://supabase.com) (free tier). No user accounts — name + affiliation only.

## What you get

- **Like** button (one like per browser)
- **Comments** with name / affiliation
- **Private** checkbox: visible only to
  - the comment author **on that same browser** (token in `localStorage`)
  - you, via **Admin view** + password

Shown on:

- About (`index.html`)
- Research posts (`layout: research`)
- Blog posts (`layout: post`)

## Setup (once)

1. Create a free Supabase project.
2. Open **SQL Editor**, paste and run `tools/supabase_feedback.sql`.
3. Set your admin password:

```sql
select public.set_feedback_admin_password('YOUR_PASSWORD_HERE');
```

4. (Recommended) lock password changes from the web:

```sql
revoke execute on function public.set_feedback_admin_password(text) from anon, authenticated;
```

5. **Project Settings → API** → copy Project URL (`https://xxxx.supabase.co`, without `/rest/v1/`) and the **publishable** key (legacy name: `anon` `public`).
6. Edit `_config.yml`:

```yaml
feedback:
  enabled: true
  supabase_url: "https://YOUR_PROJECT.supabase.co"
  supabase_anon_key: "sb_publishable_..."   # or legacy eyJ... anon key
```

Do **not** put the **secret** key in the website.
7. Commit, push, run `tools/deploy.ps1`.

Until `enabled: true` and keys are set, the Feedback block is hidden.

## Admin view

On any page with Feedback → **Admin view** → enter the password from step 3 → **Show all comments**.  
That loads public + private comments for that page only.

## Limits (by design)

- No login → “only you” for private comments means **this browser**. Clearing site data loses that view (you can still see them as admin).
- `anon` key is public (normal for static sites). RLS + RPCs keep private bodies off public selects.
