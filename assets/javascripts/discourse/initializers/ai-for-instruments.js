import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("0.11.1", (api) => {
  function insertAiButton() {
    const allowedCategoryId = parseInt(Discourse.SiteSettings.ai_for_instruments_category);

    const postMenu = document.querySelector(
      ".topic-post:first-of-type section.post__menu-area nav.post-controls .actions"
    );

    if (!postMenu) {
      console.warn("postMenu не найден, попробуем позже");
      return false;
    }

    if (postMenu.querySelector(".ai-instruments-btn")) {
      console.warn("Кнопка уже вставлена");
      return true;
    }

    const currentCategoryId = parseInt(
      document.querySelector(".topic-category [data-category-id]")?.dataset.categoryId
    );

    console.log("=== AI for Instruments Debug ===");
    console.log("allowedCategoryId:", allowedCategoryId);
    console.log("currentCategoryId:", currentCategoryId);
    console.log("postMenu найден:", postMenu);

    if (!allowedCategoryId || currentCategoryId !== allowedCategoryId) {
      console.warn("Категория не подходит, кнопка не вставляется");
      return false;
    }

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

    button.addEventListener("click", () => {
      console.log("AI кнопка нажата");
      console.log("HMAC секрет:", Discourse.SiteSettings.ai_for_instruments_hmac_secret);
      // Здесь можно добавить вызов твоего webhook
      alert("Кнопка нажата (пока без вызова webhook)");
    });

    postMenu.prepend(button);
    console.log("Кнопка успешно вставлена");
    return true;
  }

  // Первичная попытка вставки
  insertAiButton();

  // Если DOM подгружается позже, используем MutationObserver
  const observer = new MutationObserver(() => {
    const inserted = insertAiButton();
    if (inserted) {
      observer.disconnect(); // отключаем, когда кнопка вставлена
    }
  });

  observer.observe(document.body, {
    childList: true,
    subtree: true,
  });

  console.log("MutationObserver для AI кнопки активирован");
});
