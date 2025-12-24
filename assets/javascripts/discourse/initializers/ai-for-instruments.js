import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("", (api) => {
  function tryInsertButton() {
    const currentUser = api.getCurrentUser();
    const route = api.getCurrentRoute();
    const topic = route?.model;

    if (!currentUser || !topic) {
      console.debug("[AI] user or topic not ready");
      return false;
    }

    // проверка владельца
    if (topic.user_id !== currentUser.id) {
      console.debug("[AI] not topic owner");
      return false;
    }

    // категории из настроек
    const allowedCategories = (
      Discourse.SiteSettings.ai_for_instruments_categories || ""
    )
      .split("|")
      .map((id) => parseInt(id))
      .filter(Boolean);

    if (!allowedCategories.length) {
      console.debug("[AI] no categories configured");
      return false;
    }

    const currentCategoryId = parseInt(
      document.querySelector(".topic-category [data-category-id]")?.dataset
        .categoryId
    );

    if (!allowedCategories.includes(currentCategoryId)) {
      console.debug("[AI] category not allowed");
      return false;
    }

    const postMenu = document.querySelector(
      ".topic-post:first-of-type section.post__menu-area nav.post-controls .actions"
    );

    if (!postMenu) {
      console.debug("[AI] postMenu not found");
      return false;
    }

    if (postMenu.querySelector(".ai-instruments-btn")) {
      return true;
    }

    // создаём кнопку
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
          body: JSON.stringify({ topic_id: topic.id }),
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

  // MutationObserver для динамического DOM
  const observer = new MutationObserver(() => {
    if (tryInsertButton()) observer.disconnect();
  });

  observer.observe(document.body, {
    childList: true,
    subtree: true,
  });

  // первичная попытка вставки
  tryInsertButton();
  console.info("[AI] MutationObserver для кнопки активирован");
});
