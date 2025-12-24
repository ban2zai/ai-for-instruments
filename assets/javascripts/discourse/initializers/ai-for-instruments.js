import { apiInitializer } from "discourse/lib/api";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default apiInitializer("1.0", (api) => {
  const siteSettings = api.container.lookup("service:site-settings");
  const currentUser = api.getCurrentUser();

  if (!currentUser) return;

  // Парсим категории один раз
  const allowedCategories = (siteSettings.ai_for_instruments_categories || "")
    .split("|")
    .map((id) => parseInt(id, 10))
    .filter(Boolean);

  // Используем новый API (Value Transformer) вместо старых виджетов
  api.registerValueTransformer("post-menu-buttons", ({ value: buttons, context }) => {
    // context.post - это модель поста
    const post = context.post;

    // --- ПРОВЕРКИ ---
    // 1. Только первый пост темы
    if (post.post_number !== 1) return buttons;

    // 2. Только владелец поста (или админ, если нужно, но у вас проверка по владельцу)
    if (post.user_id !== currentUser.id) return buttons;

    // 3. Проверка категории
    // В трансформере category_id обычно доступен прямо в post, если нет - берем из топика
    const categoryId = post.category_id || post.topic?.category_id;
    if (!allowedCategories.includes(categoryId)) return buttons;

    // --- ДОБАВЛЕНИЕ КНОПКИ ---
    // Находим позицию перед кнопкой "delete" или в конец, если её нет.
    // Вы можете просто использовать push, чтобы добавить в конец.
    const myButton = {
      id: "ai-doc-n8n",
      name: "ai-doc-n8n",
      icon: "book",
      className: "ai-instruments-btn",
      title: "ai_for_instruments.run_process", // Ключ перевода для тултипа
      label: "ai_for_instruments.button_text", // Ключ перевода для текста
      position: "second-last-hidden", // Или можно управлять порядком через splice
      
      // В новой системе action - это прямо функция!
      action: () => {
        const dialog = api.container.lookup("service:dialog");
        
        dialog.confirm({
          message: "Отправить тему в AI для генерации документации?",
          didConfirm: () => {
            // Визуальная обратная связь (опционально можно добавить лоадер)
            ajax("/ai_for_instruments/send_webhook", {
              type: "POST",
              data: { topic_id: post.topic_id }
            })
              .then(() => {
                dialog.alert("Успешно! Задача отправлена.");
              })
              .catch(popupAjaxError);
          }
        });
      }
    };

    // Добавляем кнопку в список
    buttons.push(myButton);

    return buttons;
  });
});