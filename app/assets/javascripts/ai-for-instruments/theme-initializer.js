import { apiInitializer } from "discourse/lib/api";

export default apiInitializer(() => {
  setTimeout(() => {
    const allowedCategoryId = parseInt(Discourse.SiteSettings.ai_for_instruments_category);

    const postMenu = document.querySelector(
      ".topic-post:first-of-type section.post__menu-area nav.post-controls .actions"
    );

    console.log("allowedCategoryId:", allowedCategoryId);
    console.log("postMenu:", postMenu);

    const currentCategoryId = parseInt(
      document.querySelector(".topic-category [data-category-id]")?.dataset.categoryId
    );

    console.log("currentCategoryId:", currentCategoryId);

    if (!postMenu) {
      console.warn("postMenu не найден");
      return;
    }

    if (!allowedCategoryId || currentCategoryId !== allowedCategoryId) {
      console.warn("Категория не подходит, кнопка не вставляется");
      return;
    }

    if (postMenu.querySelector(".ai-instruments-btn")) {
      console.warn("Кнопка уже вставлена");
      return;
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
    });

    postMenu.prepend(button);
  }, 200);
});
