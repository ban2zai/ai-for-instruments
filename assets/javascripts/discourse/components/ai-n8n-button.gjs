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
  @service siteSettings;

  // Список поддерживаемых расширений
  get allowedExtensions() {
    const raw = this.siteSettings.ai_for_instruments_allowed_extensions || "cf|epf|cfe|erf";
    
    return raw.split("|").map(ext => {
      ext = ext.trim().toLowerCase();
      return ext.startsWith(".") ? ext : `.${ext}`;
    });
  }

  @action
  async handleClick() {
    const post = this.args.post;
    const topicId = post.topic_id;
    const left = post.ai_requests_left;

    // 1. Ищем файлы (используем геттер allowedExtensions)
    const files = this.extractFiles(post.cooked);

    // 2. Если файлов нет — показываем ошибку
    if (files.length === 0) {
      const extList = this.allowedExtensions.join(", ");
      this.dialog.alert(I18n.t("ai_for_instruments.no_files_found", { extensions: extList }));
      return;
    }

    // 3. Функция отправки
    const performSend = (file) => {
      ajax("/ai_for_instruments/send_webhook", {
        type: "POST",
        data: { 
          topic_id: topicId,
          // Ссылка передается абсолютно (с доменом), как сформировал extractFiles
          file_url: file.url,
          file_name: file.name
        }
      })
      .then(() => {
        this.dialog.alert(I18n.t("ai_for_instruments.success_sent"));
        // window.location.reload(); 
      })
      .catch(popupAjaxError);
    };

    // 4. Текст про лимиты
    let limitMsg = "";
    if (left !== undefined && left !== null) {
      limitMsg = `\n\n${I18n.t("ai_for_instruments.attempts_left", { count: left })}`;
    }

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
    
    // Используем динамический список
    const extensions = this.allowedExtensions;

    links.forEach((link) => {
      const href = link.getAttribute("href");
      if (!href) return;

      const lowerHref = href.toLowerCase();
      // Проверка окончания ссылки на одно из расширений
      const hasExtension = extensions.some(ext => lowerHref.endsWith(ext));

      if (hasExtension) {
        const absoluteUrl = new URL(href, window.location.origin).href;
        
        let name = link.textContent.trim();
        if (!name || name === "") {
          name = href.split("/").pop();
        }

        found.push({ name, url: absoluteUrl });
      }
    });

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