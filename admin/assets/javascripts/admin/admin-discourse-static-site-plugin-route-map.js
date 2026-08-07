export default {
  resource: "admin.adminPlugins.show",
  path: "/plugins",
  map() {
    this.route("staticSites", { path: "static-sites" });
  },
};
