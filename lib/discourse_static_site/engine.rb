# frozen_string_literal: true

module ::DiscourseStaticSite
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace DiscourseStaticSite
  end
end
