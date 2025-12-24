import { apiInitializer } from "discourse/lib/api";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { bind } from "discourse-common/utils/decorators";

export default apiInitializer("1.0", (api) => {
  const siteSettings = api.container.lookup("service:site-settings");
  const currentUser = api.getCurrentUser();

  // Если плагин выключен или юзер не залогинен — ничего не делаем
  if (!currentUser) return;

  // Парсим разрешенные категории из настроек
  const allowedCategories = (siteSettings.ai_for_instruments_categories || "")
    .split("|")
    .map((id) => parseInt(id, 10))
    .filter(Boolean);

  // 1. Добавляем кнопку в меню поста
  api.addPostMenuButton("ai-doc-n8n", (attrs) => {
    // --- ПРОВЕРКИ ВИДИМОСТИ ---

    // Только первый пост темы
    if (attrs.post_number !== 1) return;

    // Только если пользователь — автор поста (владелец темы)
    if (attrs.user_id !== currentUser.id) return;

    // Получаем текущую тему, чтобы проверить категорию
    const topicController = api.container.lookup("controller:topic");
    if (!topicController) return;

    const topic = topicController.get("model");
    // Проверяем категорию темы
    if (!topic || !allowedCategories.includes(topic.category_id)) return;

    // --- НАСТРОЙКИ КНОПКИ ---
    return {
      action: "sendToN8n",           // Имя действия (связывается ниже)
      icon: "book",                  // Иконка (FontAwesome)
      className: "ai-instruments-btn",
      title: "ai_for_instruments.run_process", // Ссылка на текст всплывающей подсказки
      label: "ai_for_instruments.button_text", // Ссылка на текст кнопки
      position: "second-last-hidden" // Позиция в меню
    };
  });

  // 2. Логика при нажатии на кнопку
  api.attachWidgetAction("post-menu", "sendToN8n", function() {
    const topicId = this.model.topic_id;
    const dialog = api.container.lookup("service:dialog");

    // Простое подтверждение на русском
    dialog.confirm({
      message: "Отправить тему в AI для генерации документации?",
      didConfirm: () => {
        // Отправка запроса на ваш серверный контроллер
        // Обратите внимание: путь должен совпадать с routes.rb
        ajax("/ai_for_instruments/send_webhook", {
          type: "POST",
          data: { topic_id: topicId }
        })
          .then(() => {
            dialog.alert("Успешно! Задача отправлена.");
          })
          .catch(popupAjaxError);
      }
    });
  });
});