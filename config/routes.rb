# frozen_string_literal: true

DiscourseStaticSite::Engine.routes.draw do
  namespace :admin, constraints: AdminConstraint.new do
    resources :deployments, only: %i[index create update destroy] do
      post :deploy, on: :member
    end
  end

  get "/content/:slug" => "content#show"
  get "/content/:slug/*path" => "content#show"
end
