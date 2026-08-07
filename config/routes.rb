# frozen_string_literal: true

DiscourseStaticSite::Engine.routes.draw do
  namespace :admin, constraints: AdminConstraint.new do
    resources :deployments, only: %i[index create update destroy] do
      post :deploy, on: :member
    end
  end

  get "/content/:slug" => "content#show", format: false
  get "/content/:slug/*path" => "content#show", format: false
end
