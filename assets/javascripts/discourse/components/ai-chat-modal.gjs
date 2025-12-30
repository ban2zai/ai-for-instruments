import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { inject as service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import I18n from "discourse-i18n";
import DModal from "discourse/components/d-modal";
import DButton from "discourse/components/d-button";
import TextField from "discourse/components/text-field";
import { next } from "@ember/runloop";

export default class AiChatModal extends Component {
  @service dialog;
  @tracked messages = [];
  @tracked newMessage = "";
  @tracked loading = false;
  @tracked loadingHistory = true;

  constructor() {
    super(...arguments);
    this.loadHistory();
  }

  async loadHistory() {
    try {
      const response = await ajax("/ai_for_instruments/chat_history", {
        data: { post_id: this.args.model.post.id }
      });
      this.messages = response.history || [];
      this.scrollToBottom();
    } catch (e) {
      popupAjaxError(e);
    } finally {
      this.loadingHistory = false;
    }
  }

  @action
  async sendMessage() {
    if (!this.newMessage.trim() || this.loading) return;

    const userMsg = this.newMessage;
    this.newMessage = "";
    this.loading = true;

    // Оптимистичное добавление сообщения пользователя (сервер тоже сохранит, но так быстрее для UI)
    this.messages = [...this.messages, { role: "user", content: userMsg }];
    this.scrollToBottom();

    try {
      const response = await ajax("/ai_for_instruments/chat", {
        type: "POST",
        data: { 
          post_id: this.args.model.post.id,
          message: userMsg
        }
      });

      this.messages = [...this.messages, { role: "assistant", content: response.reply }];
      this.scrollToBottom();
    } catch (e) {
      popupAjaxError(e);
    } finally {
      this.loading = false;
    }
  }

  @action
  async clearChat() {
    if (await this.dialog.confirm(I18n.t("ai_for_instruments.chat.confirm_clear"))) {
      try {
        await ajax("/ai_for_instruments/clear_chat", {
          type: "POST",
          data: { post_id: this.args.model.post.id }
        });
        this.messages = [];
      } catch (e) {
        popupAjaxError(e);
      }
    }
  }

  @action
  handleKeyDown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault();
      this.sendMessage();
    }
  }

  scrollToBottom() {
    next(() => {
      const container = document.querySelector(".ai-chat-messages");
      if (container) {
        container.scrollTop = container.scrollHeight;
      }
    });
  }

  <template>
    <DModal
      @title={{I18n.t "ai_for_instruments.chat.title"}}
      @closeModal={{@closeModal}}
      class="ai-chat-modal"
    >
      <:body>
        <div class="ai-chat-container">
          <div class="ai-chat-messages">
            {{#if this.loadingHistory}}
              <div class="loading-container">
                <div class="spinner"></div>
              </div>
            {{else}}
              {{#each this.messages as |msg|}}
                <div class="chat-message {{msg.role}}">
                  <div class="message-header">
                    <span class="role-name">
                      {{#if (eq msg.role "user")}}
                        {{I18n.t "ai_for_instruments.chat.you"}}
                      {{else}}
                        {{I18n.t "ai_for_instruments.chat.ai"}}
                      {{/if}}
                    </span>
                  </div>
                  <div class="message-content">
                    {{msg.content}}
                  </div>
                </div>
              {{/each}}
              
              {{#if this.loading}}
                <div class="chat-message assistant typing">
                  <div class="message-content">
                    <span class="typing-indicator">...</span>
                  </div>
                </div>
              {{/if}}
              
              {{#if (eq this.messages.length 0)}}
                <div class="chat-empty">
                  {{I18n.t "ai_for_instruments.chat.empty_state"}}
                </div>
              {{/if}}
            {{/if}}
          </div>
          
          <div class="ai-chat-input-area">
            <TextField
              @value={{this.newMessage}}
              @placeholderKey="ai_for_instruments.chat.placeholder"
              {{on "keydown" this.handleKeyDown}}
              autofocus="true"
              class="chat-input-field"
            />
            <DButton
              @icon="paper-plane"
              @action={{this.sendMessage}}
              @disabled={{this.loading}}
              class="btn-primary send-msg-btn"
            />
          </div>
        </div>
      </:body>

      <:footer>
        <DButton
          @icon="trash-can"
          @action={{this.clearChat}}
          @label="ai_for_instruments.chat.clear_button"
          class="btn-danger btn-flat chat-clear-btn"
        />
        <DButton
          @action={{@closeModal}}
          @label="close"
          class="btn-flat"
        />
      </:footer>
    </DModal>

    <style>
      .ai-chat-container {
        display: flex;
        flex-direction: column;
        height: 500px;
        max-height: 70vh;
      }
      .ai-chat-messages {
        flex: 1;
        overflow-y: auto;
        padding: 15px;
        background: var(--secondary-very-low);
        border-radius: 8px;
        margin-bottom: 15px;
      }
      .chat-message {
        margin-bottom: 15px;
        max-width: 85%;
        padding: 10px 14px;
        border-radius: 12px;
      }
      .chat-message.user {
        margin-left: auto;
        background: var(--tertiary-low);
        color: var(--primary);
      }
      .chat-message.assistant {
        margin-right: auto;
        background: var(--primary-low);
        color: var(--primary);
      }
      .message-header {
        font-size: 0.8em;
        font-weight: bold;
        margin-bottom: 4px;
        opacity: 0.7;
      }
      .message-content {
        white-space: pre-wrap;
        word-break: break-word;
      }
      .ai-chat-input-area {
        display: flex;
        gap: 10px;
      }
      .chat-input-field {
        flex: 1;
      }
      .chat-empty {
        text-align: center;
        color: var(--primary-medium);
        margin-top: 50px;
      }
      .loading-container {
        display: flex;
        justify-content: center;
        align-items: center;
        height: 100%;
      }
    </style>
  </template>
}
