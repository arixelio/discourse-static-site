# frozen_string_literal: true

RSpec.describe "Discourse Static Site" do
  before { enable_current_plugin }

  let(:admin) { Fabricate(:admin) }
  let(:attributes) do
    {
      name: "Docs",
      slug: "docs",
      repository_url: "https://secret-token@example.com/owner/docs.git",
      branch: "main",
    }
  end

  it "keeps deployment management admin-only" do
    get "/static-sites/admin/deployments.json"

    expect(response.status).to eq(404)
  end

  it "stores the token encrypted and never returns it" do
    sign_in(admin)

    post "/static-sites/admin/deployments.json", params: { deployment: attributes }

    expect(response.status).to eq(200)
    deployment = DiscourseStaticSite::Deployment.last
    expect(deployment.repository_url).to eq("https://example.com/owner/docs.git")
    expect(deployment.token).to eq("secret-token")
    expect(deployment.token_ciphertext).not_to include("secret-token")
    expect(response.body).not_to include("secret-token")
  end

  it "serves deployed HTML with both CSP sandboxing and the height bridge" do
    Dir.mktmpdir do |directory|
      allow(DiscourseStaticSite).to receive(:storage_path).and_return(Pathname.new(directory))
      deployment =
        DiscourseStaticSite::Deployment.create!(
          attributes.except(:repository_url).merge(
            repository_url: "https://example.com/owner/docs.git",
            status: "deployed",
          ),
        )
      FileUtils.mkdir_p(deployment.deployed_path)
      File.write(
        deployment.deployed_path.join("index.html"),
        "<html><head></head><body>Docs</body></html>",
      )

      get "/static-sites/content/docs/"

      expect(response.status).to eq(200)
      expect(response.headers["Content-Security-Policy"]).to include("sandbox allow-scripts")
      expect(response.body).to include("discourse-static-site:height")
    end
  end

  it "returns not found before a site has deployed" do
    DiscourseStaticSite::Deployment.create!(
      attributes
        .except(:repository_url)
        .merge(repository_url: "https://example.com/owner/docs.git"),
    )

    get "/pages/docs.json"

    expect(response.status).to eq(404)
  end
end
