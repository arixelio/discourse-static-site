import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

export default <template>
  <div class="static-sites-admin admin-detail">
    <div class="static-sites-admin__header">
      <div>
        <h1>{{i18n "discourse_static_site.admin.title"}}</h1>
        <p>{{i18n "discourse_static_site.admin.description"}}</p>
      </div>
      <div>
        <button type="button" class="btn" {{on "click" @controller.refresh}}>
          {{i18n "discourse_static_site.admin.refresh"}}
        </button>
        <button
          type="button"
          class="btn btn-primary"
          {{on "click" @controller.newSite}}
        >
          {{i18n "discourse_static_site.admin.new"}}
        </button>
      </div>
    </div>

    {{#if @controller.editingId}}
      <form class="static-sites-admin__form" {{on "submit" @controller.save}}>
        <label>
          {{i18n "discourse_static_site.admin.name"}}
          <input
            required
            value={{@controller.form.name}}
            {{on "input" (fn @controller.updateField "name")}}
          />
        </label>
        <label>
          {{i18n "discourse_static_site.admin.slug"}}
          <input
            required
            pattern="[a-z0-9]+(?:-[a-z0-9]+)*"
            value={{@controller.form.slug}}
            {{on "input" (fn @controller.updateField "slug")}}
          />
        </label>
        <label>
          {{i18n "discourse_static_site.admin.repository_url"}}
          <input
            required
            type="url"
            autocomplete="off"
            value={{@controller.form.repository_url}}
            {{on "input" (fn @controller.updateField "repository_url")}}
          />
          <small>{{i18n "discourse_static_site.admin.repository_hint"}}</small>
        </label>
        <label>
          {{i18n "discourse_static_site.admin.branch"}}
          <input
            required
            value={{@controller.form.branch}}
            {{on "input" (fn @controller.updateField "branch")}}
          />
        </label>
        <div>
          <button
            type="submit"
            class="btn btn-primary"
            disabled={{@controller.saving}}
          >
            {{i18n "discourse_static_site.admin.save"}}
          </button>
          <button type="button" class="btn" {{on "click" @controller.cancel}}>
            {{i18n "discourse_static_site.admin.cancel"}}
          </button>
        </div>
      </form>
    {{/if}}

    {{#if @controller.sites.length}}
      <div class="static-sites-admin__list">
        {{#each @controller.sites as |site|}}
          <article>
            <div>
              <h3>{{site.name}}</h3>
              <a
                href={{site.page_url}}
                target="_blank"
                rel="noopener noreferrer"
              >
                {{site.page_url}}
              </a>
              <p>{{site.repository_url}} · {{site.branch}}</p>
              <p>
                {{i18n "discourse_static_site.admin.status"}}:
                {{site.status}}
                {{#if site.commit_sha}} · {{site.commit_sha}}{{/if}}
                {{#if site.deployed_at}} · {{site.deployed_at}}{{/if}}
              </p>
              {{#if site.last_error}}<pre>{{site.last_error}}</pre>{{/if}}
            </div>
            <div class="static-sites-admin__actions">
              <button
                type="button"
                class="btn"
                {{on "click" (fn @controller.edit site)}}
              >
                {{i18n "discourse_static_site.admin.edit"}}
              </button>
              <button
                type="button"
                class="btn btn-primary"
                disabled={{eq site.status "deploying"}}
                {{on "click" (fn @controller.deploy site)}}
              >
                {{i18n "discourse_static_site.admin.deploy"}}
              </button>
              <button
                type="button"
                class="btn btn-danger"
                {{on "click" (fn @controller.remove site)}}
              >
                {{i18n "discourse_static_site.admin.delete"}}
              </button>
            </div>
          </article>
        {{/each}}
      </div>
    {{else}}
      <p>{{i18n "discourse_static_site.admin.empty"}}</p>
    {{/if}}
  </div>
</template>
