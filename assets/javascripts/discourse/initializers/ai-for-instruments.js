import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("", (api) => {
  function tryInsertButton() {
    const currentUser = api.getCurrentUser();
    if (!currentUser) return false;

    const topicElement = document.querySelector(".topic-post:first-of-type");
    if (!topicElement) return false;

    const topicId = parseInt(topicElement.dataset.postId || topicElement.dataset.topicId);
    if (!topicId) return false;

    const topicUserId = parseInt(topicElement.dataset.userId);
    if (topicUserId !== currentUser.id) return false; // проверка владельца

    const currentCategoryId = parseInt(
      document.querySelector(".topic-category [data-category-id]")?.dataset.categoryId
    );

    const allowedCategories = (
      Discourse.SiteSettings.ai_for_instruments_categories || ""
    )
      .split("|")
      .map((id) => parseInt(id))
      .filter(Boolean);

    if (!allowedCategories.includes(currentCategoryId)) return false;

    const postMenu = topicElement.querySelector(
      "section.post__menu-area nav.post-controls .actions"
    );
    if (!postMenu) return false;

    if (postMenu.querySelector(".ai-instruments-btn")) return true;

    const button = document.createElement("button");
    button.className = "btn btn-icon-text btn-flat ai-instruments-btn";
    button.type = "button";
    button.innerHTML = `
      <svg class="fa d-icon d-icon-book svg-icon" aria-hidden="true">
        <use href="#book"></use>
      </svg>
      <span class="d-button-label">AI-документация</span>
    `;

    button.addEventListener("click", async () => {
      button.disabled = true;
      button.classList.add("is-loading");

      try {
        const res = await fetch("/ai-for-instruments/send-topic", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": api.getCSRFToken(),
          },
          body: JSON.stringify({ topic_id: topicId }),
        });

        if (!res.ok) throw new Error("Request failed");
        alert("Задача отправлена в AI");
      } catch (e) {
        console.error("[AI] send-topic error:", e);
        alert("Ошибка при отправке");
      } finally {
        button.disabled = false;
        button.classList.remove("is-loading");
      }
    });

    postMenu.prepend(button);
    console.info("[AI] button inserted");
    return true;
  }

  const observer = new MutationObserver(() => {
    if (tryInsertButton()) observer.disconnect();
  });

  observer.observe(document.body, { childList: true, subtree: true });

  // первичная попытка вставки
  tryInsertButton();
});
