(() => {
  // postId -> { attempts, timerId }
  const pollingState = new Map();

  function findMessagesList() {
    // 最優先：idで拾う（あなたのHTMLに合わせる）
    return document.querySelector("#messages_list[data-ai-polling-post-id]") ||
      document.querySelector("[data-ai-polling-post-id]");
  }

  function getPostId(el) {
    const v = el?.dataset?.aiPollingPostId;
    if (!v) return null;
    if (!/^\d+$/.test(v)) return null;
    return v;
  }

  function getStatusUrl(el, postId) {
    const explicit = el?.dataset?.aiStatusUrl;
    if (explicit && explicit.startsWith("/")) return explicit;
    return `/buddy_talks/${postId}/ai_status`;
  }

  // 「考え中（pending）」があるときだけポーリングする
  function hasPending(el) {
    if (!el) return false;

    // pending partialが placeholder_id をDOM idとして持ってる想定（ai_pending_xxx）
    // どちらでも拾えるように複数条件で検出
    return !!(
      el.querySelector('[id^="ai_pending_"]') ||
      el.querySelector("[data-ai-pending='1']") ||
      el.querySelector(".js-ai-pending") ||
      // テキスト検知（最後の保険。文言変えたら効かないので保険扱い）
      (el.textContent && el.textContent.includes("バディが考え中"))
    );
  }

  function stop(postId) {
    const st = pollingState.get(postId);
    if (!st) return;
    if (st.timerId) clearInterval(st.timerId);
    pollingState.delete(postId);
  }

  async function pollOnce(el, postId) {
    const st = pollingState.get(postId);
    if (!st) return;

    // pending が消えたなら（＝表示上もう待ってない）ポーリング停止
    if (!hasPending(el)) {
      stop(postId);
      return;
    }

    st.attempts += 1;

    const maxAttempts = 60; // 約3分（初回投稿は長めにしとく）
    const url = getStatusUrl(el, postId);
    if (!url) {
      stop(postId);
      return;
    }

    try {
      const res = await fetch(url, {
        headers: { Accept: "application/json" },
        credentials: "same-origin"
      });

      // 404/401 など致命は即停止（エラー増殖防止）
      if (!res.ok) {
        if ([401, 403, 404, 422, 500].includes(res.status) || st.attempts >= maxAttempts) {
          stop(postId);
        }
        return;
      }

      const data = await res.json();

      if (data?.completed) {
        stop(postId);

        // Turboがいるならreplaceで同URL再訪問して最新メッセージを再描画
        if (window.Turbo) {
          Turbo.visit(window.location.href, { action: "replace" });
        } else {
          window.location.reload();
        }
        return;
      }

      if (st.attempts >= maxAttempts) stop(postId);
    } catch (_) {
      if (st.attempts >= maxAttempts) stop(postId);
    }
  }

  function startIfNeeded() {
    const el = findMessagesList();
    if (!el) return;

    const postId = getPostId(el);
    if (!postId) return;

    // pendingが無いなら起動しない（無限叩きを防ぐ）
    if (!hasPending(el)) return;

    if (pollingState.has(postId)) return;

    const st = { attempts: 0, timerId: null };
    pollingState.set(postId, st);

    const interval = 3000;
    st.timerId = setInterval(() => pollOnce(el, postId), interval);

    // 初回即実行（体感改善）
    pollOnce(el, postId);
  }

  // Turboのキャッシュに入る前に停止（戻る/進むでタイマー残留しがち）
  document.addEventListener("turbo:before-cache", () => {
    for (const postId of pollingState.keys()) stop(postId);
  });

  // 初回ロード & Turbo遷移
  document.addEventListener("DOMContentLoaded", startIfNeeded);
  document.addEventListener("turbo:load", startIfNeeded);
  document.addEventListener("turbo:render", startIfNeeded);
  document.addEventListener("turbo:frame-load", startIfNeeded);

  // DOMに pending が append された瞬間も拾う（startのturbo_streamやreply後）
  const observer = new MutationObserver(() => startIfNeeded());
  observer.observe(document.documentElement, { childList: true, subtree: true });
})();
