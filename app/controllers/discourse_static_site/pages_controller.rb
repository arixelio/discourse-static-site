# frozen_string_literal: true

module DiscourseStaticSite
  class PagesController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    def show
      deployment = Deployment.find_by(slug: params[:slug], status: "deployed")
      index = deployment&.deployed_path&.join("index.html")
      raise Discourse::NotFound if index.nil? || !index.file?

      render_json_dump(
        name: deployment.name,
        iframe_url: "#{Discourse.base_path}/static-sites/content/#{deployment.slug}/",
      )
    end
  end
end
