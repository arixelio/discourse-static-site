import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class StaticSitePageRoute extends DiscourseRoute {
  model({ slug }) {
    return ajax(`/pages/${encodeURIComponent(slug)}.json`);
  }
}
