# frozen_string_literal: true

require "fileutils"
require "find"
require "open3"
require "tmpdir"

module Jobs
  class DeployStaticSite < ::Jobs::Base
    def execute(args)
      deployment = DiscourseStaticSite::Deployment.find_by(id: args[:deployment_id])
      return if deployment.nil?

      deployment.ensure_public_host!
      FileUtils.mkdir_p(DiscourseStaticSite.storage_path)

      Dir.mktmpdir("deploy-", DiscourseStaticSite.storage_path) do |temporary|
        checkout = File.join(temporary, "site")
        clone!(deployment, checkout, temporary)
        sha = git!("-C", checkout, "rev-parse", "HEAD").strip
        FileUtils.rm_rf(File.join(checkout, ".git"))
        validate_checkout!(checkout)
        deployment.with_lock do
          publish!(checkout, deployment.deployed_path) do
            deployment.update!(
              status: "deployed",
              commit_sha: sha,
              deployed_at: Time.zone.now,
              last_error: nil,
            )
          end
        end
      end
    rescue StandardError => e
      if deployment&.persisted? && DiscourseStaticSite::Deployment.exists?(deployment.id)
        deployment.update_columns(status: "failed", last_error: filtered_error(e, deployment))
      end
    end

    private

    def clone!(deployment, checkout, temporary)
      askpass = File.join(temporary, "askpass")
      File.write(askpass, <<~'SH')
        #!/bin/sh
        case "$1" in
          *Username*) printf '%s\n' "$DSS_GIT_TOKEN" ;;
          *Password*) printf '\n' ;;
        esac
      SH
      File.chmod(0o700, askpass)
      env = {
        "DSS_GIT_TOKEN" => deployment.token.to_s,
        "GIT_ASKPASS" => askpass,
        "GIT_TERMINAL_PROMPT" => "0",
      }
      git!(
        "-c",
        "http.followRedirects=false",
        "clone",
        "--depth=1",
        "--single-branch",
        "--no-tags",
        "--branch=#{deployment.branch}",
        "--",
        deployment.repository_url,
        checkout,
        env: env,
      )
    end

    def validate_checkout!(checkout)
      index = File.join(checkout, "index.html")
      raise "Repository root must contain index.html" unless File.file?(index)

      bytes = 0
      max_size_mb = SiteSetting.discourse_static_site_max_size_mb
      Find.find(checkout) do |path|
        stat = File.lstat(path)
        raise "Symbolic links are not allowed" if stat.symlink?
        next unless stat.file?

        bytes += stat.size
        raise "Deployed files exceed the #{max_size_mb}MB limit" if bytes > max_size_mb.megabytes
      end
    end

    def publish!(checkout, target)
      previous = Pathname.new("#{target}.previous")
      FileUtils.mv(previous, target) if previous.exist? && !target.exist?
      FileUtils.rm_rf(previous)
      FileUtils.mv(target, previous) if target.exist?
      FileUtils.mv(checkout, target)
      swapped = true
      yield
      FileUtils.rm_rf(previous)
    rescue StandardError
      FileUtils.rm_rf(target) if swapped
      FileUtils.mv(previous, target) if previous.exist? && !target.exist?
      raise
    end

    def git!(*args, env: {})
      output, error, status = Open3.capture3(env, "git", *args)
      raise(error.presence || output.presence || "Git command failed") unless status.success?

      output
    end

    def filtered_error(error, deployment)
      message = error.message.to_s.scrub
      token = deployment&.token.to_s
      message = message.gsub(token, "[FILTERED]") if token.present?
      message.first(2000)
    rescue StandardError
      "Deployment failed"
    end
  end
end
