import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import eq from "truth-helpers/helpers/eq";

import DModal from "discourse/components/d-modal";
import DButton from "discourse/components/d-button";

export default class AiFileSelectionModal extends Component {
  @tracked selectedFile = this.args.model.files[0];

  @action
  selectFile(file) {
    this.selectedFile = file;
  }

  @action
  confirm() {
    this.args.closeModal();
    if (this.args.model.onConfirm) {
      this.args.model.onConfirm(this.selectedFile);
    }
  }

  <template>
    <DModal
      @title={{@model.title}}
      @closeModal={{@closeModal}}
      class="ai-file-selection-modal"
    >
      <:body>
        <p>{{@model.message}}</p>
        
        <div class="control-group">
          {{#each @model.files as |file|}}
            <div class="radio" style="margin-bottom: 10px;">
              <label style="cursor: pointer; display: flex; align-items: center;">
                <input
                  type="radio"
                  name="ai_file_select"
                  checked={{eq this.selectedFile.url file.url}}
                  {{on "change" (fn this.selectFile file)}}
                />
                <span style="margin-left: 8px; font-weight: bold;">{{file.name}}</span>
              </label>
              <div style="font-size: 0.85em; color: #888; margin-left: 24px;">
                {{file.url}}
              </div>
            </div>
          {{/each}}
        </div>
      </:body>

      <:footer>
        <DButton
          @action={{this.confirm}}
          @label="ai_for_instruments.send_button"
          class="btn-primary"
        />
        <DButton
          @action={{@closeModal}}
          @label="cancel"
          class="btn-flat"
        />
      </:footer>
    </DModal>
  </template>
}