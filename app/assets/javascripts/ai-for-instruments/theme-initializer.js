import { apiInitializer } from "discourse/lib/api";

export default apiInitializer(api => {
  function insertButton() {
    // проверяем выбранную категорию в настройках
    const allowedCategoryId = parseInt(Discourse.SiteSettings.ai_for_instruments_category, 10);
    if (!allowedCategoryId) return;

    // ищем категорию в DOM
    const categorySpan = document.querySelector(".topic-category [data-category-id]");
    const currentCategoryId = categorySpan ? parseInt(categorySpan.dataset.categoryId, 10) : 0;

    // если категория не совпадает, не показываем кнопку
    if (allowedCategoryId > 0 && currentCategoryId !== allowedCategoryId) return;

    // ищем меню поста первого сообщения
    const postMenu = document.querySelector(
      ".topic-post:first-of-type section.post__menu-area nav.post-controls .actions"
    );
    if (!postMenu) return;
    if (postMenu.querySelector(".ai-instruments-btn")) return; // защита от повторного добавления

    // создаём кнопку
    const button = document.createElement("button");
    button.className = "btn btn-icon-text btn-flat ai-instruments-btn";
    button.type = "button";
    button.title = "AI-документация";

    button.innerHTML = `
      <svg class="fa d-icon d-icon-book svg-icon" aria-hidden="true">
        <use href="#book"></use>
      </svg>
      <span class="d-button-label">AI-документация</span>
    `;

    button.addEventListener("click", async () => {
      const topicId = parseInt(document.querySelector("#topic-title h1").dataset.topicId, 10);
      const topicSlug = location.pathname.split("/t/")[1]?.split("/")[0] || "";
      const topicUrl = `${window.location.origin}/t/${topicSlug}/${topicId}`;

      try {
        const response = await fetch("/ai_for_instruments/send_webhook", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ topic_id: topicId, topic_url: topicUrl }),
        });

        if (!response.ok) {
          alert("Ошибка при отправке webhook");
          return;
        }

        alert("Webhook успешно отправлен!");
      } catch (err) {
        console.error(err);
        alert("Ошибка при отправке webhook");
      }
    });

    postMenu.prepend(button);
  }

  // при загрузке страницы и навигации в SPA
  api.onPageChange(() => {
    // даём Discourse дорендерить DOM
    setTimeout(insertButton, 500);
  });
});
