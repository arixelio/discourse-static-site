# frozen_string_literal: true

RSpec.describe Jobs::DeployStaticSite do
  it "uses the configured deployed site size limit" do
    SiteSetting.discourse_static_site_max_size_mb = 1

    Dir.mktmpdir do |directory|
      File.write(File.join(directory, "index.html"), "")
      File.truncate(File.join(directory, "index.html"), 1.megabyte + 1)

      expect { described_class.new.send(:validate_checkout!, directory) }.to raise_error(
        "Deployed files exceed the 1MB limit",
      )
    end
  end
end
