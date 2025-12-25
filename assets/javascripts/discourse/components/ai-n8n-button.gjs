import Component from "@glimmer/component";
import { action } from "@ember/object";
import DButton from "discourse/components/d-button";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { inject as service } from "@ember/service";
import I18n from "discourse-i18n";
import AiFileSelectionModal from "./ai-file-selection-modal";

export default class AiN8nButton extends Component {
  @service dialog;
  @service modal;

  // Список поддерживаемых расширений
  allowedExtensions = [".cf", ".epf", ".efd", ".cfe"];

  @action
  async handleClick() {
    const post = this.args.post;
    const topicId = post.topic_id;
    const left = post.ai_requests_left;

    // 1. Ищем файлы
    const files = this.extractFiles(post.cooked);

    // 2. Если файлов нет — показываем ошибку с перечислением расширений
    if (files.length === 0) {
      const extList = this.allowedExtensions.join(", "); // ".cf, .epf, .efd, .cfe"
      this.dialog.alert(I18n.t("ai_for_instruments.no_files_found", { extensions: extList }));
      return;
    }

    // 3. Функция отправки
    const performSend = (file) => {
      ajax("/ai_for_instruments/send_webhook", {
        type: "POST",
        data: { 
          topic_id: topicId,
          file_url: file.url,
          file_name: file.name
        }
      })
      .then(() => {
        this.dialog.alert(I18n.t("ai_for_instruments.success_sent"));
        window.location.reload(); // Раскомментируйте, если нужно обновлять счетчик сразу
      })
      .catch(popupAjaxError);
    };

    // 4. Текст про лимиты
    let limitMsg = "";
    if (left !== undefined && left !== null) {
      limitMsg = `\n\n${I18n.t("ai_for_instruments.attempts_left", { count: left })}`;
    }

    // 5. ВСЕГДА открываем модальное окно (даже если файл один)
    await this.modal.show(AiFileSelectionModal, {
      model: {
        title: I18n.t("ai_for_instruments.select_file_title"),
        message: `${I18n.t("ai_for_instruments.select_file_msg")}${limitMsg}`,
        files: files,
        onConfirm: performSend
      }
    });
  }

  extractFiles(htmlContent) {
    const parser = new DOMParser();
    const doc = parser.parseFromString(htmlContent, "text/html");
    const links = doc.querySelectorAll("a");
    const found = [];

    links.forEach((link) => {
      const href = link.getAttribute("href");
      if (!href) return;

      const lowerHref = href.toLowerCase();
      const hasExtension = this.allowedExtensions.some(ext => lowerHref.endsWith(ext));

      if (hasExtension) {
        const absoluteUrl = new URL(href, window.location.origin).href;
        let name = link.textContent.trim();
        if (!name || name === "") {
          name = href.split("/").pop();
        }

        found.push({ name, url: absoluteUrl });
      }
    });

    // Убираем дубликаты
    const uniqueFiles = [];
    const seenUrls = new Set();
    found.forEach(f => {
      if (!seenUrls.has(f.url)) {
        seenUrls.add(f.url);
        uniqueFiles.push(f);
      }
    });

    return uniqueFiles;
  }

  <template>
    <DButton
      @icon="book"
      @action={{this.handleClick}}
      @label="ai_for_instruments.button_text"
      @title="ai_for_instruments.run_process"
      class="ai-instruments-btn"
    />
  </template>
}