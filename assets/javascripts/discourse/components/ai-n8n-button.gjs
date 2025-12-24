import Component from "@glimmer/component";
import { action } from "@ember/object";
import DButton from "discourse/components/d-button";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { inject as service } from "@ember/service";

export default class AiN8nButton extends Component {
  @service dialog;

  @action
  async sendToN8n() {
    // this.args.post доступен автоматически из контекста меню
    const topicId = this.args.post.topic_id;

    this.dialog.confirm({
      message: "Отправить тему в AI для генерации документации?",
      didConfirm: () => {
        ajax("/ai_for_instruments/send_webhook", {
          type: "POST",
          data: { topic_id: topicId }
        })
          .then(() => {
            this.dialog.alert("Успешно! Задача отправлена.");
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