(function () {
  var root = document.getElementById("feedback");
  if (!root) return;

  var url = root.getAttribute("data-supabase-url");
  var key = root.getAttribute("data-supabase-anon-key");
  var pageId = root.getAttribute("data-page-id") || "/";
  if (!url || !key || typeof window.supabase === "undefined") {
    setStatus("Feedback is not configured yet.", true);
    return;
  }

  var client = window.supabase.createClient(url, key);
  var CLIENT_KEY = "rcil_feedback_client_id";
  var TOKEN_KEY = "rcil_feedback_tokens";
  var NAME_KEY = "rcil_feedback_name";
  var AFF_KEY = "rcil_feedback_affiliation";

  var likeBtn = document.getElementById("feedback-like-btn");
  var likeCountEl = document.getElementById("feedback-like-count");
  var likeLabel = document.getElementById("feedback-like-label");
  var listEl = document.getElementById("feedback-comment-list");
  var emptyEl = document.getElementById("feedback-empty");
  var form = document.getElementById("feedback-form");
  var statusEl = document.getElementById("feedback-status");
  var adminToggle = document.getElementById("feedback-admin-toggle");
  var adminPanel = document.getElementById("feedback-admin-panel");
  var adminLoad = document.getElementById("feedback-admin-load");
  var adminStatus = document.getElementById("feedback-admin-status");

  function uuid() {
    if (window.crypto && crypto.randomUUID) return crypto.randomUUID();
    return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, function (c) {
      var r = (Math.random() * 16) | 0;
      var v = c === "x" ? r : (r & 0x3) | 0x8;
      return v.toString(16);
    });
  }

  function getClientId() {
    var id = localStorage.getItem(CLIENT_KEY);
    if (!id) {
      id = uuid();
      localStorage.setItem(CLIENT_KEY, id);
    }
    return id;
  }

  function getTokens() {
    var raw = localStorage.getItem(TOKEN_KEY);
    if (!raw) return [];
    var parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];
    return parsed.filter(function (t) { return typeof t === "string" && t.length > 0; });
  }

  function addToken(token) {
    var tokens = getTokens();
    if (tokens.indexOf(token) === -1) {
      tokens.push(token);
      localStorage.setItem(TOKEN_KEY, JSON.stringify(tokens));
    }
  }

  function setStatus(msg, isError) {
    statusEl.textContent = msg || "";
    statusEl.classList.toggle("is-error", !!isError);
  }

  function setAdminStatus(msg, isError) {
    adminStatus.textContent = msg || "";
    adminStatus.classList.toggle("is-error", !!isError);
  }

  function escapeHtml(s) {
    return String(s)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function formatDate(iso) {
    var d = new Date(iso);
    if (isNaN(d.getTime())) return "";
    return d.toLocaleDateString(undefined, {
      year: "numeric",
      month: "short",
      day: "numeric"
    });
  }

  function renderComments(rows) {
    listEl.innerHTML = "";
    if (!rows || rows.length === 0) {
      emptyEl.hidden = false;
      emptyEl.textContent = "No comments yet. Be the first.";
      listEl.appendChild(emptyEl);
      return;
    }
    emptyEl.hidden = true;
    rows.forEach(function (row) {
      var article = document.createElement("article");
      article.className = "feedback-comment" + (row.is_private ? " is-private" : "");
      var meta = escapeHtml(row.author_name || "Anonymous");
      if (row.affiliation) meta += " · " + escapeHtml(row.affiliation);
      meta += " · " + escapeHtml(formatDate(row.created_at));
      var badges = "";
      if (row.is_private) badges += '<span class="feedback-badge">Private</span>';
      if (row.is_mine) badges += '<span class="feedback-badge feedback-badge-mine">Yours</span>';
      article.innerHTML =
        '<header class="feedback-comment-meta">' + meta + badges + "</header>" +
        '<p class="feedback-comment-body">' + escapeHtml(row.body).replace(/\n/g, "<br>") + "</p>";
      listEl.appendChild(article);
    });
  }

  function loadLikes() {
    return client
      .from("page_likes")
      .select("client_id")
      .eq("page_id", pageId)
      .then(function (res) {
        if (res.error) throw res.error;
        var rows = res.data || [];
        var mine = rows.some(function (r) { return r.client_id === getClientId(); });
        likeCountEl.textContent = String(rows.length);
        likeBtn.setAttribute("aria-pressed", mine ? "true" : "false");
        likeBtn.classList.toggle("is-liked", mine);
        likeLabel.textContent = mine ? "Liked" : "Like";
      });
  }

  function loadComments() {
    return client
      .rpc("fetch_page_comments", {
        p_page_id: pageId,
        p_tokens: getTokens()
      })
      .then(function (res) {
        if (res.error) throw res.error;
        renderComments(res.data || []);
      });
  }

  function toggleLike() {
    var liked = likeBtn.getAttribute("aria-pressed") === "true";
    likeBtn.disabled = true;
    var req;
    if (liked) {
      req = client.rpc("remove_page_like", {
        p_page_id: pageId,
        p_client_id: getClientId()
      });
    } else {
      req = client
        .from("page_likes")
        .insert({ page_id: pageId, client_id: getClientId() });
    }
    return req.then(function (res) {
      if (res.error) throw res.error;
      return loadLikes();
    }).finally(function () {
      likeBtn.disabled = false;
    });
  }

  form.addEventListener("submit", function (e) {
    e.preventDefault();
    var name = document.getElementById("feedback-name").value.trim();
    var affiliation = document.getElementById("feedback-affiliation").value.trim();
    var body = document.getElementById("feedback-body").value.trim();
    var isPrivate = document.getElementById("feedback-private").checked;
    if (!name || !body) {
      setStatus("Name and comment are required.", true);
      return;
    }

    var payload = {
      page_id: pageId,
      author_name: name,
      affiliation: affiliation,
      body: body,
      is_private: isPrivate,
      viewer_token: null
    };
    var token = null;
    if (isPrivate) {
      token = uuid();
      payload.viewer_token = token;
    }

    var submitBtn = document.getElementById("feedback-submit");
    submitBtn.disabled = true;
    setStatus("Posting…");

    client
      .from("page_comments")
      .insert(payload)
      .then(function (res) {
        if (res.error) throw res.error;
        localStorage.setItem(NAME_KEY, name);
        localStorage.setItem(AFF_KEY, affiliation);
        if (token) addToken(token);
        form.reset();
        document.getElementById("feedback-name").value = name;
        document.getElementById("feedback-affiliation").value = affiliation;
        setStatus(isPrivate
          ? "Private comment posted. Only you (this browser) and the site author can see it."
          : "Comment posted.");
        return loadComments();
      })
      .catch(function (err) {
        setStatus(err.message || "Could not post comment.", true);
      })
      .finally(function () {
        submitBtn.disabled = false;
      });
  });

  likeBtn.addEventListener("click", function () {
    toggleLike().catch(function (err) {
      setStatus(err.message || "Could not update like.", true);
    });
  });

  adminToggle.addEventListener("click", function () {
    adminPanel.hidden = !adminPanel.hidden;
  });

  adminLoad.addEventListener("click", function () {
    var password = document.getElementById("feedback-admin-password").value;
    if (!password) {
      setAdminStatus("Enter the admin password.", true);
      return;
    }
    adminLoad.disabled = true;
    setAdminStatus("Loading…");
    client
      .rpc("fetch_page_comments_admin", {
        p_page_id: pageId,
        p_password: password
      })
      .then(function (res) {
        if (res.error) throw res.error;
        renderComments(res.data || []);
        setAdminStatus("Showing all comments for this page (including private).");
      })
      .catch(function (err) {
        setAdminStatus(err.message || "Admin load failed.", true);
      })
      .finally(function () {
        adminLoad.disabled = false;
      });
  });

  var savedName = localStorage.getItem(NAME_KEY);
  var savedAff = localStorage.getItem(AFF_KEY);
  if (savedName) document.getElementById("feedback-name").value = savedName;
  if (savedAff) document.getElementById("feedback-affiliation").value = savedAff;

  Promise.all([loadLikes(), loadComments()]).catch(function (err) {
    setStatus(err.message || "Could not load feedback.", true);
    if (emptyEl) emptyEl.textContent = "Could not load comments.";
  });
})();
