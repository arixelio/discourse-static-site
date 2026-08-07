# frozen_string_literal: true

require "ipaddr"
require "resolv"
require "uri"

module DiscourseStaticSite
  class Deployment < ::ActiveRecord::Base
    self.table_name = "discourse_static_site_deployments"

    SLUG_PATTERN = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/
    BRANCH_PATTERN = %r{\A[a-zA-Z0-9][a-zA-Z0-9._/-]{0,199}\z}
    BLOCKED_NETWORKS = %w[
      0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16
      172.16.0.0/12 192.0.0.0/24 192.168.0.0/16 224.0.0.0/4 240.0.0.0/4
      ::/128 ::1/128 fc00::/7 fe80::/10 ff00::/8
    ].map { |network| IPAddr.new(network) }.freeze

    validates :name, presence: true, length: { maximum: 100 }
    validates :slug,
              presence: true,
              uniqueness: true,
              length: { maximum: 80 },
              format: { with: SLUG_PATTERN }
    validates :branch, presence: true, format: { with: BRANCH_PATTERN }
    validate :validate_branch
    validate :validate_repository_url

    def assign_repository(value)
      previous_host = URI.parse(repository_url).host if repository_url.present?
      uri = self.class.parse_repository_url(value)
      if uri.user.present?
        decoded_token = URI::DEFAULT_PARSER.unescape(uri.user)
        if !decoded_token.valid_encoding? || decoded_token.length > 500 ||
             decoded_token.match?(/[[:cntrl:]]/)
          raise URI::InvalidURIError, "token is invalid"
        end
        self.token = decoded_token
      elsif previous_host.present? && previous_host != uri.host
        self.token = nil
      end
      uri.userinfo = nil
      self.repository_url = uri.to_s
    end

    def token
      return if token_ciphertext.blank?

      self.class.encryptor.decrypt_and_verify(token_ciphertext)
    end

    def token=(value)
      self.token_ciphertext =
        value.present? ? self.class.encryptor.encrypt_and_sign(value) : nil
    end

    def deployed_path
      DiscourseStaticSite.storage_path.join(id.to_s)
    end

    def ensure_public_host!
      host = URI.parse(repository_url).host
      addresses = Resolv.getaddresses(host)
      raise "Repository host could not be resolved" if addresses.empty?

      blocked = addresses.any? do |address|
        ip = IPAddr.new(address)
        ip = ip.native if ip.ipv4_mapped?
        BLOCKED_NETWORKS.any? { |network| network.include?(ip) }
      end
      raise "Repository host resolves to a non-public address" if blocked
    end

    def admin_json
      {
        id: id,
        name: name,
        slug: slug,
        repository_url: repository_url,
        branch: branch,
        status: status,
        commit_sha: commit_sha,
        deployed_at: deployed_at,
        last_error: last_error,
        has_token: token_ciphertext.present?,
        page_url: "#{Discourse.base_path}/pages/#{slug}",
      }
    end

    def self.parse_repository_url(value)
      uri = URI.parse(value.to_s)
      if uri.scheme != "https" || uri.host.blank? || uri.password.present? || uri.query.present? ||
           uri.fragment.present? || uri.path.blank? || uri.path == "/"
        raise URI::InvalidURIError, "must be an HTTPS Git URL using https://<token>@host/path"
      end
      uri
    rescue URI::InvalidURIError
      raise
    rescue StandardError
      raise URI::InvalidURIError, "must be a valid HTTPS Git URL"
    end

    def self.encryptor
      @encryptor ||=
        ActiveSupport::MessageEncryptor.new(
          ActiveSupport::KeyGenerator
            .new(GlobalSetting.safe_secret_key_base)
            .generate_key("discourse-static-site-token", 32),
          cipher: "aes-256-gcm",
        )
    end

    private

    def validate_repository_url
      self.class.parse_repository_url(repository_url)
    rescue URI::InvalidURIError => e
      errors.add(:repository_url, e.message)
    end

    def validate_branch
      if branch&.include?("..") || branch&.include?("@{") || branch&.end_with?(".lock", "/", ".")
        errors.add(:branch, "is not a valid Git branch")
      end
    end
  end
end
