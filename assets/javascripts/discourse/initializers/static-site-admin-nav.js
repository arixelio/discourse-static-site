import { withPluginApi } from "discourse/lib/plugin-api";

const PLUGIN_ID = "discourse-static-site";

export default {
  name: "static-site-admin-nav",

  initialize(container) {
    if (!container.lookup("service:current-user")?.admin) {
      return;
    }

    withPluginApi((api) => {
      api.setAdminPluginIcon(PLUGIN_ID, "globe");
      api.addAdminPluginConfigurationNav(PLUGIN_ID, [
        {
          label: "discourse_static_site.admin.title",
          route: "adminPlugins.show.staticSites",
        },
      ]);
    });
  },
};
