# frozen_string_literal: true

class CreateDiscourseStaticSiteDeployments < ActiveRecord::Migration[7.0]
  def change
    create_table :discourse_static_site_deployments do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :repository_url, null: false
      t.text :token_ciphertext
      t.string :branch, null: false, default: "main"
      t.string :status, null: false, default: "not_deployed"
      t.string :commit_sha
      t.datetime :deployed_at
      t.text :last_error
      t.timestamps
    end

    add_index :discourse_static_site_deployments, :slug, unique: true
  end
end
