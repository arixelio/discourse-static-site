# frozen_string_literal: true

module DiscourseStaticSite
  def self.storage_path
    # ponytail: local storage is for one web container; use shared storage before scaling out.
    Rails.root.join("tmp", "discourse-static-site")
  end
end
