import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsShowStaticSitesRoute extends DiscourseRoute {
  model() {
    return ajax("/static-sites/admin/deployments.json");
  }

  setupController(controller, model) {
    super.setupController(controller, model);
    controller.sites = model.deployments;
  }
}
