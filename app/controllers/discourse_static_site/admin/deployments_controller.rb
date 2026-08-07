# frozen_string_literal: true

module DiscourseStaticSite
  module Admin
    class DeploymentsController < ::Admin::AdminController
      requires_plugin PLUGIN_NAME

      def index
        render_json_dump(deployments: Deployment.order(:name).map(&:admin_json))
      end

      def create
        deployment = Deployment.new(deployment_params.except(:repository_url))
        deployment.assign_repository(deployment_params[:repository_url])
        deployment.save!
        render_json_dump(deployment: deployment.admin_json)
      rescue URI::InvalidURIError => e
        render_json_error e.message, status: 422
      end

      def update
        deployment = Deployment.find(params[:id])
        attributes = deployment_params.except(:repository_url)
        deployment.assign_repository(deployment_params[:repository_url])
        deployment.update!(attributes)
        render_json_dump(deployment: deployment.admin_json)
      rescue URI::InvalidURIError => e
        render_json_error e.message, status: 422
      end

      def destroy
        deployment = Deployment.find(params[:id])
        deployment.with_lock do
          path = deployment.deployed_path
          deployment.destroy!
          FileUtils.rm_rf(path) if path.to_s.start_with?("#{DiscourseStaticSite.storage_path}/")
          FileUtils.rm_rf("#{path}.previous")
        end
        render json: success_json
      end

      def deploy
        deployment = Deployment.find(params[:id])
        deployment.with_lock do
          if deployment.status == "deploying"
            raise Discourse::InvalidParameters, "Deployment is already running"
          end

          deployment.update!(status: "deploying", last_error: nil)
          Jobs.enqueue(:deploy_static_site, deployment_id: deployment.id)
        end
        render_json_dump(deployment: deployment.admin_json)
      end

      private

      def deployment_params
        params.require(:deployment).permit(:name, :slug, :repository_url, :branch)
      end
    end
  end
end
