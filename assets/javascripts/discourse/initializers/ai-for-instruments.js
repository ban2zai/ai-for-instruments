import { apiInitializer } from "discourse/lib/api";
import AiN8nButton from "../components/ai-n8n-button"; // Импортируем наш новый компонент

export default apiInitializer("1.0", (api) => {
  const siteSettings = api.container.lookup("service:site-settings");
  const currentUser = api.getCurrentUser();

  if (!currentUser) return;

  const allowedCategories = (siteSettings.ai_for_instruments_categories || "")
    .split("|")
    .map((id) => parseInt(id, 10))
    .filter(Boolean);

  // Используем трансформер для кнопок
  api.registerValueTransformer("post-menu-buttons", ({ value: dag, context: { post } }) => {
    
    // 1. Проверки (тот же код, что и раньше)
    if (post.post_number !== 1) return dag;
    if (post.user_id !== currentUser.id) return dag;

    const categoryId = post.category_id || post.topic?.category_id;
    if (!allowedCategories.includes(categoryId)) return dag;

    // 2. Добавляем кнопку через dag.add
    // Синтаксис: dag.add("уникальный-ключ", КлассКомпонента, { опции })
    dag.add("ai-doc-n8n", AiN8nButton, {
      before: "delete", // Поставить перед кнопкой удаления (или используйте after: "...")
    });

    return dag;
  });
});