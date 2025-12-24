import { apiInitializer } from "discourse/lib/api";
import AiN8nButton from "../components/ai-n8n-button";
import AiResetButton from "../components/ai-reset-button"; // Импорт второй кнопки

export default apiInitializer("1.0", (api) => {
  const siteSettings = api.container.lookup("service:site-settings");
  const currentUser = api.getCurrentUser();

  if (!currentUser) return;

  const allowedCategories = (siteSettings.ai_for_instruments_categories || "")
    .split("|")
    .map((id) => parseInt(id, 10))
    .filter(Boolean);

  api.registerValueTransformer("post-menu-buttons", ({ value: dag, context: { post } }) => {
    // Базовые проверки
    if (post.post_number !== 1) return dag;
    
    const categoryId = post.category_id || post.topic?.category_id;
    if (!allowedCategories.includes(categoryId)) return dag;

    const isOwner = post.user_id === currentUser.id;
    const isAdmin = currentUser.admin;

    // 1. Добавляем основную кнопку (Видит владелец или Админ)
    if (isOwner || isAdmin) {
      dag.add("ai-doc-n8n", AiN8nButton, {
        before: "reply",
      });
    }

    // 2. Добавляем кнопку сброса (Видит ТОЛЬКО Админ)
    if (isAdmin) {
      dag.add("ai-doc-reset", AiResetButton, {
        after: "ai-doc-n8n", // Ставим сразу после основной кнопки AI
      });
    }

    return dag;
  });
});