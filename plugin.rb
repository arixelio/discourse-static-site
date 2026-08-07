# frozen_string_literal: true

# name: discourse-static-site
# about: Deploy built static sites from HTTPS Git repositories into Discourse pages.
# version: 0.0.1
# authors: thehrz
# url: https://github.com/thehrz/discourse-static-site
# required_version: 2.7.0

enabled_site_setting :discourse_static_site_enabled
register_asset "stylesheets/common/static-site.scss"
register_svg_icon "globe"
add_admin_route "discourse_static_site.admin.title",
                "discourse-static-site",
                use_new_show_route: true

module ::DiscourseStaticSite
  PLUGIN_NAME = "discourse-static-site"
end

require_relative "lib/discourse_static_site"
require_relative "lib/discourse_static_site/engine"

after_initialize do
  Rails.application.config.filter_parameters.concat(%i[repository_url token])

  Discourse::Application.routes.append do
    get "/pages/:slug" => "discourse_static_site/pages#show"
    get "/admin/plugins/discourse-static-site/static-sites" => "admin/plugins#index",
        constraints: AdminConstraint.new
    mount ::DiscourseStaticSite::Engine, at: "/static-sites"
  end
end
