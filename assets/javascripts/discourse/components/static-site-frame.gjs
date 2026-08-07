import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { trustHTML } from "@ember/template";

export default class StaticSiteFrame extends Component {
  @tracked availableHeight = 1;
  @tracked contentHeight = 0;

  willDestroy() {
    super.willDestroy(...arguments);
    window.removeEventListener("message", this.onMessage);
    window.removeEventListener("resize", this.resize);
    document.body.classList.remove("discourse-static-site-page");
  }

  get style() {
    return trustHTML(
      `height:${Math.max(this.availableHeight, this.contentHeight)}px`
    );
  }

  @action
  setup(element) {
    this.element = element;
    this.resize = () => {
      this.contentHeight = 0;
      this.availableHeight = Math.max(
        1,
        Math.floor(window.innerHeight - element.getBoundingClientRect().top)
      );
    };
    this.onMessage = (event) => {
      if (
        event.source === element.contentWindow &&
        event.data?.type === "discourse-static-site:height"
      ) {
        const height = Number(event.data.height);
        if (Number.isFinite(height) && height > 0) {
          this.contentHeight = Math.ceil(height);
        }
      }
    };
    this.resize();
    window.addEventListener("message", this.onMessage);
    window.addEventListener("resize", this.resize);
    document.body.classList.add("discourse-static-site-page");
  }

  <template>
    <iframe
      {{didInsert this.setup}}
      class="static-site-frame"
      src={{@src}}
      title={{@title}}
      sandbox="allow-scripts allow-popups allow-popups-to-escape-sandbox"
      scrolling="no"
      style={{this.style}}
    ></iframe>
  </template>
}
