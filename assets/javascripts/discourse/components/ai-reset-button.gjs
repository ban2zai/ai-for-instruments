import Component from "@glimmer/component";
import { action } from "@ember/object";
import DButton from "discourse/components/d-button";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { inject as service } from "@ember/service";

export default class AiResetButton extends Component {
  @service dialog;

  @action
  async resetLimit() {
    const topicId = this.args.post.topic_id;

    this.dialog.confirm({
      message: "Сбросить суточный лимит запросов AI для этой темы?",
      didConfirm: () => {
        ajax("/ai_for_instruments/reset_limit", {
          type: "POST",
          data: { topic_id: topicId }
        })
          .then(() => {
            this.dialog.alert("Лимит сброшен.");
            // Перезагрузка страницы, чтобы пользователь сразу увидел изменение (сериализатор обновился)
            window.location.reload(); 
          })
          .catch(popupAjaxError);
      }
    });
  }

  <template>
    <DButton
      @icon="sync"
      @action={{this.resetLimit}}
      @label="ai_for_instruments.reset_button_text"
      class="btn-danger ai-reset-btn"
    />
  </template>
}