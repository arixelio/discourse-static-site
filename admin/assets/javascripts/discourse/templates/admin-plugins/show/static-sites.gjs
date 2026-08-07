import { fn } from "@ember/helper";
import AdminConfigAreaEmptyList from "discourse/admin/components/admin-config-area-empty-list";
import Form from "discourse/components/form";
import { eq } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import DPageSubheader from "discourse/ui-kit/d-page-subheader";
import { i18n } from "discourse-i18n";

export default <template>
  <section class="static-sites-admin admin-detail">
    <DPageSubheader
      @titleLabel={{i18n "discourse_static_site.admin.title"}}
      @descriptionLabel={{i18n "discourse_static_site.admin.description"}}
    >
      <:actions as |actions|>
        {{#unless @controller.editingId}}
          <actions.Default
            @action={{@controller.refresh}}
            @icon="arrows-rotate"
            @label="discourse_static_site.admin.refresh"
          />
          <actions.Primary
            @action={{@controller.newSite}}
            @icon="plus"
            @label="discourse_static_site.admin.new"
          />
        {{/unless}}
      </:actions>
    </DPageSubheader>

    {{#if @controller.editingId}}
      <Form
        @data={{@controller.form}}
        @onSubmit={{@controller.save}}
        class="static-sites-admin__form"
        as |form|
      >
        <form.Field
          @name="name"
          @title={{i18n "discourse_static_site.admin.name"}}
          @validation="required"
          @format="large"
          @type="input"
          as |field|
        >
          <field.Control />
        </form.Field>
        <form.Field
          @name="slug"
          @title={{i18n "discourse_static_site.admin.slug"}}
          @validation="required"
          @format="large"
          @type="input"
          as |field|
        >
          <field.Control pattern="[a-z0-9]+(?:-[a-z0-9]+)*" />
        </form.Field>
        <form.Field
          @name="repository_url"
          @title={{i18n "discourse_static_site.admin.repository_url"}}
          @description={{i18n "discourse_static_site.admin.repository_hint"}}
          @validation="required|url"
          @format="large"
          @type="input-url"
          as |field|
        >
          <field.Control autocomplete="off" />
        </form.Field>
        <form.Field
          @name="branch"
          @title={{i18n "discourse_static_site.admin.branch"}}
          @validation="required"
          @format="large"
          @type="input"
          as |field|
        >
          <field.Control />
        </form.Field>
        <form.Actions>
          <form.Submit @label="discourse_static_site.admin.save" />
          <form.Button
            @action={{@controller.cancel}}
            @label="discourse_static_site.admin.cancel"
          />
        </form.Actions>
      </Form>
    {{else if @controller.sites.length}}
      <table class="d-table static-sites-admin__list">
        <thead class="d-table__head">
          <tr class="d-table__row">
            <th class="d-table__cell">
              {{i18n "discourse_static_site.admin.name"}}
            </th>
            <th class="d-table__cell">
              {{i18n "discourse_static_site.admin.status"}}
            </th>
            <th class="d-table__cell"></th>
          </tr>
        </thead>
        <tbody class="d-table__body">
          {{#each @controller.sites as |site|}}
            <tr class="d-table__row">
              <td class="d-table__cell --overview">
                <a
                  href={{site.page_url}}
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  {{site.name}}
                </a>
                <div class="static-sites-admin__repository">
                  {{site.repository_url}}
                  ·
                  {{site.branch}}
                </div>
              </td>
              <td class="d-table__cell">
                <div>{{site.status}}</div>
                {{#if site.commit_sha}}<div>{{site.commit_sha}}</div>{{/if}}
                {{#if site.deployed_at}}<div>{{site.deployed_at}}</div>{{/if}}
                {{#if site.last_error}}
                  <pre
                    class="static-sites-admin__error"
                  >{{site.last_error}}</pre>
                {{/if}}
              </td>
              <td class="d-table__cell --controls">
                <div class="static-sites-admin__actions">
                  <DButton
                    @action={{fn @controller.edit site}}
                    @icon="pencil"
                    @label="discourse_static_site.admin.edit"
                    class="btn-small"
                  />
                  <DButton
                    @action={{fn @controller.deploy site}}
                    @disabled={{eq site.status "deploying"}}
                    @icon="rocket"
                    @label="discourse_static_site.admin.deploy"
                    class="btn-primary btn-small"
                  />
                  <DButton
                    @action={{fn @controller.remove site}}
                    @icon="trash-can"
                    @label="discourse_static_site.admin.delete"
                    class="btn-danger btn-small"
                  />
                </div>
              </td>
            </tr>
          {{/each}}
        </tbody>
      </table>
    {{else}}
      <AdminConfigAreaEmptyList
        @emptyLabel="discourse_static_site.admin.empty"
        @ctaLabel="discourse_static_site.admin.new"
        @ctaAction={{@controller.newSite}}
      />
    {{/if}}
  </section>
</template>
