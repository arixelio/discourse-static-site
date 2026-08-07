import { tracked } from "@glimmer/tracking";
import Controller from "@ember/controller";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";

const emptyForm = () => ({
  name: "",
  slug: "",
  repository_url: "",
  branch: "main",
});

export default class AdminPluginsShowStaticSitesController extends Controller {
  @service dialog;

  @tracked sites = [];
  @tracked form = emptyForm();
  @tracked editingId = null;
  @tracked saving = false;

  @action
  newSite() {
    this.editingId = "new";
    this.form = emptyForm();
  }

  @action
  edit(site) {
    this.editingId = site.id;
    this.form = {
      name: site.name,
      slug: site.slug,
      repository_url: site.repository_url,
      branch: site.branch,
    };
  }

  @action
  cancel() {
    this.editingId = null;
    this.form = emptyForm();
  }

  @action
  updateField(field, event) {
    this.form = { ...this.form, [field]: event.target.value };
  }

  @action
  async save(event) {
    event.preventDefault();
    this.saving = true;
    try {
      const creating = this.editingId === "new";
      const path = creating
        ? "/static-sites/admin/deployments.json"
        : `/static-sites/admin/deployments/${this.editingId}.json`;
      const result = await ajax(path, {
        type: creating ? "POST" : "PUT",
        data: { deployment: this.form },
      });
      this.sites = creating
        ? [...this.sites, result.deployment].sort((a, b) =>
            a.name.localeCompare(b.name)
          )
        : this.sites.map((site) =>
            site.id === result.deployment.id ? result.deployment : site
          );
      this.cancel();
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.saving = false;
    }
  }

  @action
  async deploy(site) {
    try {
      const result = await ajax(
        `/static-sites/admin/deployments/${site.id}/deploy.json`,
        { type: "POST" }
      );
      this.replace(result.deployment);
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  remove(site) {
    return this.dialog.confirm({
      message: i18n("discourse_static_site.admin.confirm_delete"),
      didConfirm: async () => {
        try {
          await ajax(`/static-sites/admin/deployments/${site.id}.json`, {
            type: "DELETE",
          });
          this.sites = this.sites.filter(({ id }) => id !== site.id);
        } catch (error) {
          popupAjaxError(error);
        }
      },
    });
  }

  @action
  async refresh() {
    try {
      const result = await ajax("/static-sites/admin/deployments.json");
      this.sites = result.deployments;
    } catch (error) {
      popupAjaxError(error);
    }
  }

  replace(deployment) {
    this.sites = this.sites.map((site) =>
      site.id === deployment.id ? deployment : site
    );
  }
}
