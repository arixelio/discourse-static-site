import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { trustHTML } from "@ember/template";

export default class StaticSiteFrame extends Component {
  @tracked height = 600;

  willDestroy() {
    super.willDestroy(...arguments);
    window.removeEventListener("message", this.onMessage);
    document.body.classList.remove("discourse-static-site-page");
  }

  get style() {
    return trustHTML(`height:${this.height}px`);
  }

  @action
  setup(element) {
    this.element = element;
    this.onMessage = (event) => {
      if (
        event.source === element.contentWindow &&
        event.data?.type === "discourse-static-site:height"
      ) {
        const height = Number(event.data.height);
        if (Number.isFinite(height) && height > 0) {
          this.height = Math.ceil(height);
        }
      }
    };
    window.addEventListener("message", this.onMessage);
    document.body.classList.add("discourse-static-site-page");
  }

  <template>
    <iframe
      {{didInsert this.setup}}
      class="static-site-frame"
      src={{@src}}
      title={{@title}}
      sandbox="allow-scripts allow-popups allow-popups-to-escape-sandbox"
      style={{this.style}}
    ></iframe>
  </template>
}
