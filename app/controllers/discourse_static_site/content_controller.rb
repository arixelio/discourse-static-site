# frozen_string_literal: true

module DiscourseStaticSite
  class ContentController < ::ApplicationController
    requires_plugin PLUGIN_NAME
    skip_before_action :check_xhr
    skip_before_action :verify_authenticity_token

    MOUNTED_TEXT_EXTENSIONS = %w[.css .html .js .json .mjs].freeze

    HEIGHT_BRIDGE = <<~HTML.squish.freeze
      <script>(() => {
        const send = () => requestAnimationFrame(() => parent.postMessage({
          type: "discourse-static-site:height",
          height: Math.max(document.documentElement.scrollHeight, document.body?.scrollHeight || 0)
        }, "*"));
        new ResizeObserver(send).observe(document.documentElement);
        addEventListener("load", send);
        send();
      })()</script>
    HTML

    def show
      deployment = Deployment.find_by(slug: params[:slug], status: "deployed")
      raise Discourse::NotFound if deployment.nil?

      root = deployment.deployed_path.realpath
      relative = params[:path].presence || "index.html"
      segments = relative.split("/")
      hidden_path = segments.any? { |part| part.start_with?(".") }
      if relative.include?("\0") || relative.include?("\\") || hidden_path
        raise Discourse::NotFound
      end

      requested = root.join(relative).cleanpath
      raise Discourse::NotFound unless requested.to_s.start_with?("#{root}/")
      requested = requested.join("index.html") if requested.directory?
      requested = root.join("index.html") unless requested.file? || File.extname(relative).present?
      raise Discourse::NotFound unless requested.file?

      response.headers["Access-Control-Allow-Origin"] = "*"
      response.headers["Cache-Control"] = "no-cache"
      response.headers["X-Content-Type-Options"] = "nosniff"

      type = Rack::Mime.mime_type(requested.extname, "application/octet-stream")
      if type == "text/html"
        response.headers["Content-Security-Policy"] =
          "sandbox allow-scripts allow-popups allow-popups-to-escape-sandbox; " \
            "default-src 'self' https: data: blob:; " \
            "script-src 'self' https: blob: 'unsafe-inline' 'unsafe-eval'; " \
            "style-src 'self' https: 'unsafe-inline'; connect-src 'self' https:"
        base = content_base(deployment)
        html = mount_root_paths(requested.read, base)
        additions = %(<base href="#{base}">#{HEIGHT_BRIDGE})
        html =
          if html.match?(/<head(?:\s[^>]*)?>/i)
            html.sub(/<head(?:\s[^>]*)?>/i) { |head| "#{head}#{additions}" }
          else
            "#{additions}#{html}"
          end
        send_data html, type: type, disposition: "inline"
      elsif MOUNTED_TEXT_EXTENSIONS.include?(requested.extname)
        send_data mount_root_paths(requested.read, content_base(deployment)),
                  type: type,
                  disposition: "inline"
      else
        send_file requested, type: type, disposition: "inline"
      end
    rescue Errno::ENOENT
      raise Discourse::NotFound
    end

    private

    def content_base(deployment)
      "/static-sites/content/#{deployment.slug}/"
    end

    def mount_root_paths(content, base)
      content
        .gsub(/(["'`])\/(?![\/>$&])/) { "#{Regexp.last_match(1)}#{base}" }
        .gsub("url(/", "url(#{base}")
    end
  end
end
