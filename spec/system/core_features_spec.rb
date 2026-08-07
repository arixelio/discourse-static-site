# frozen_string_literal: true

# Parts of the core features examples can be skipped like so:
#   it_behaves_like "having working core features", skip_examples: %i[login likes]
#
# List of keywords for skipping examples:
# login, likes, profile, topics, topics:read, topics:reply, topics:create,
# search, search:quick_search, search:full_page
#
# For more details, see https://meta.discourse.org/t/-/361381
RSpec.describe "Core features" do
  before { enable_current_plugin }

  it_behaves_like "having working core features"

  fab!(:admin)

  it "opens static site management from the plugin settings button" do
    sign_in(admin)
    visit "/admin/plugins"

    find('[data-plugin-setting-button="discourse-static-site"]').click

    expect(page).to have_current_path("/admin/plugins/discourse-static-site/static-sites")
    expect(page).to have_css(".static-sites-admin")
  end
end
