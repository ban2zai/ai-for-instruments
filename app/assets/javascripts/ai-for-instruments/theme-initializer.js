import { apiInitializer } from "discourse/lib/api";

export default apiInitializer((api) => {
  const ALLOWED_CATEGORY_ID = parseInt(Discourse.SiteSettings.ai_for_instruments_category);

  function insertButton(postMenu) {
    if (!postMenu) return;

    // Проверка, что кнопка ещё не вставлена
    if (postMenu.querySelector(".ai-instruments-btn")) return;

    const currentCategoryId = parseInt(
      document.querySelector(".topic-category [data-category-id]")?.dataset.categoryId
    );

    if (!ALLOWED_CATEGORY_ID || currentCategoryId !== ALLOWED_CATEGORY_ID) {
      return; // Категория не подходит
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
      alert("Кнопка нажата!");
      // Здесь можно вызывать свой контроллер плагина через fetch/post
    });

    postMenu.prepend(button);
  }

  // MutationObserver для динамических изменений DOM
  const observer = new MutationObserver((mutations) => {
    const postMenu = document.querySelector(
      ".topic-post:first-of-type section.post__menu-area nav.post-controls .actions"
    );
    if (postMenu) insertButton(postMenu);
  });

  observer.observe(document.body, { childList: true, subtree: true });

  // Для первичной вставки при полной загрузке
  api.onPageChange(() => {
    setTimeout(() => {
      const postMenu = document.querySelector(
        ".topic-post:first-of-type section.post__menu-area nav.post-controls .actions"
      );
      insertButton(postMenu);
    }, 200);
  });
});
