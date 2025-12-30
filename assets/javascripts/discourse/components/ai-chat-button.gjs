import Component from "@glimmer/component";
import { action } from "@ember/object";
import DButton from "discourse/components/d-button";
import { inject as service } from "@ember/service";
import I18n from "discourse-i18n";
import AiChatModal from "./ai-chat-modal";

export default class AiChatButton extends Component {
  @service modal;

  @action
  showChat() {
    this.modal.show(AiChatModal, {
      model: {
        post: this.args.post,
      }
    });
  }

  <template>
    <DButton
      @icon="comment"
      @action={{this.showChat}}
      @label="ai_for_instruments.chat.button_text"
      @title="ai_for_instruments.chat.button_title"
      class="ai-chat-btn"
    />
  </template>
}
