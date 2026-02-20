function startPollingIfNeeded() {
  const el = document.querySelector("[data-ai-polling-post-id]");
  if (!el) return;

  const postId = el.dataset.aiPollingPostId;
  if (!postId) return;

  // 二重起動防止
  if (el.dataset.aiPollingStarted === "1") return;
  el.dataset.aiPollingStarted = "1";

  let attempts = 0;
  const maxAttempts = 40; // 約2分
  const interval = 3000;

  const timer = setInterval(async () => {
    attempts++;

    try {
      const res = await fetch(`/buddy_talks/${postId}/ai_status`, {
        headers: { Accept: "application/json" }
      });
      if (!res.ok) return;

      const data = await res.json();

      if (data.completed) {
        clearInterval(timer);
        Turbo.visit(window.location.href, { action: "replace" });
      }

      if (attempts >= maxAttempts) clearInterval(timer);
    } catch (_) {
      if (attempts >= maxAttempts) clearInterval(timer);
    }
  }, interval);
}

document.addEventListener("turbo:load", startPollingIfNeeded);
document.addEventListener("turbo:render", startPollingIfNeeded);
document.addEventListener("turbo:frame-load", startPollingIfNeeded);