import StaticSiteFrame from "../components/static-site-frame";

export default <template>
  <div class="static-site-page">
    <StaticSiteFrame
      @src={{@controller.model.iframe_url}}
      @title={{@controller.model.name}}
    />
  </div>
</template>
