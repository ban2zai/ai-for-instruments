import Component from "@glimmer/component";
import { action } from "@ember/object";
import DButton from "discourse/components/d-button";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { inject as service } from "@ember/service";
import I18n from "discourse-i18n";

export default class AiN8nButton extends Component {
  @service dialog;

  @action
  async sendToN8n() {
    const topicId = this.args.post.topic_id;

    if (left !== undefined && left !== null) {
      msg += `\n\n${I18n.t("ai_for_instruments.attempts_left", { count: left })}`;
    }
    
    this.dialog.confirm({
      message: msg,
      didConfirm: () => {
        ajax("/ai_for_instruments/send_webhook", {
          type: "POST",
          data: { topic_id: topicId }
        })
          .then(() => {
            this.dialog.alert(I18n.t("ai_for_instruments.success_sent"));
            // Опционально: перезагрузить страницу, чтобы обновить счетчик
            // window.location.reload(); 
          })
          .catch(popupAjaxError);
      }
    });
  }

  <template>
    <DButton
      @icon="book"
      @action={{this.sendToN8n}}
      @label="ai_for_instruments.button_text"
      @title="ai_for_instruments.run_process"
      class="ai-instruments-btn"
    />
  </template>
}