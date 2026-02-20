document.addEventListener("turbo:load", () => {
  const container = document.querySelector("[data-ai-polling-post-id]");
  if (!container) return;

  const postId = container.dataset.aiPollingPostId;
  if (!postId) return;

  let attempts = 0;
  const maxAttempts = 40; // 約2分
  const interval = 3000;

  const timer = setInterval(async () => {
    attempts++;

    try {
      const res = await fetch(`/buddy_talks/${postId}/ai_status`);
      if (!res.ok) return;

      const data = await res.json();

      if (data.completed) {
        clearInterval(timer);
        Turbo.visit(window.location.href);
      }

      if (attempts >= maxAttempts) {
        clearInterval(timer);
      }

    } catch (_) {
      if (attempts >= maxAttempts) clearInterval(timer);
    }
  }, interval);
});
