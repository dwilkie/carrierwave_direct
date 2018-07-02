# encoding: utf-8

require "securerandom"
require "carrierwave_direct/uploader/content_type"
require "carrierwave_direct/uploader/direct_url"

module CarrierWaveDirect
  module Uploader
    extend ActiveSupport::Concern

    FILENAME_WILDCARD = "${filename}"

    included do
      storage :fog

      attr_accessor :success_action_redirect
      attr_accessor :success_action_status

      fog_credentials.keys.each do |key|
        define_method(key) do
          fog_credentials[key]
        end
      end
    end

    include CarrierWaveDirect::Uploader::ContentType
    include CarrierWaveDirect::Uploader::DirectUrl

    #ensure that region returns something. Since sig v4 it is required in the signing key & credentials
    def region
      defined?(super) ? super : "us-east-1"
    end

    def acl
      fog_public ? 'public-read' : 'private'
    end

    def policy(options = {}, &block)
      options[:expiration] ||= upload_expiration
      options[:min_file_size] ||= min_file_size
      options[:max_file_size] ||= max_file_size

      @date ||= Time.now.utc.strftime("%Y%m%d")
      @timestamp ||= Time.now.utc.strftime("%Y%m%dT%H%M%SZ")
      @policy ||= generate_policy(options, &block)
    end

    def date
      @timestamp ||= Time.now.utc.strftime("%Y%m%dT%H%M%SZ")
    end

    def algorithm
      'AWS4-HMAC-SHA256'
    end

    def credential
      @date ||= Time.now.utc.strftime("%Y%m%d")
      "#{aws_access_key_id}/#{@date}/#{region}/s3/aws4_request"
    end

    def clear_policy!
      @policy = nil
      @date = nil
      @timestamp = nil
    end

    def signature
      OpenSSL::HMAC.hexdigest(
        'sha256',
        signing_key,
        policy
      )
    end

    def url_scheme_white_list
      nil
    end

    def persisted?
      false
    end

    def key
      return @key if @key.present?
      if present?
        identifier = model.send("#{mounted_as}_identifier")
        self.key = "#{store_dir}/#{identifier}"
      else
        @key = "#{store_dir}/#{guid}/#{FILENAME_WILDCARD}"
      end
      @key
    end

    def key=(k)
      @key = k
      update_version_keys(:with => @key)
    end

    def guid
      SecureRandom.uuid
    end

    def has_key?
      key !~ /#{Regexp.escape(FILENAME_WILDCARD)}\z/
    end

    def key_regexp
      /\A(#{store_dir}|#{cache_dir})\/[a-f\d\-]+\/.+\.(?i)#{extension_regexp}(?-i)\z/
    end

    def extension_regexp
      allowed_file_types = extension_whitelist
      extension_regexp = allowed_file_types.present? && allowed_file_types.any? ?  "(#{allowed_file_types.join("|")})" : "\\w+"
    end

    def filename
      unless has_key?
        # Use the attached models remote url to generate a new key otherwise return nil
        remote_url = model.send("remote_#{mounted_as}_url")
        remote_url ? key_from_file(CarrierWave::SanitizedFile.new(remote_url).filename) : return
      end

      key_path = key.split("/")
      filename_parts = []
      filename_parts.unshift(key_path.pop)
      unique_key = key_path.pop
      filename_parts.unshift(unique_key) if unique_key
      filename_parts.join("/")
    end

    private

    def decoded_key
      URI.decode(URI.parse(url).path[1 .. -1])
    end

    def key_from_file(fname)
      new_key_parts = key.split("/")
      new_key_parts.pop
      new_key_parts << fname
      self.key = new_key_parts.join("/")
    end

    # Update the versions to use this key
    def update_version_keys(options)
      versions.each do |name, uploader|
        uploader.key = options[:with]
      end
    end

    # Put the version name at the end of the filename since the guid is also stored
    # e.g. guid/filename_thumb.jpg instead of CarrierWave's default: thumb_guid/filename.jpg
    def full_filename(for_file)
      extname = File.extname(for_file)
      [for_file.chomp(extname), version_name].compact.join('_') << extname
    end

    def generate_policy(options)
      conditions = []

      conditions << ["starts-with", "$utf8", ""] if options[:enforce_utf8]
      conditions << ["starts-with", "$key", key.sub(/#{Regexp.escape(FILENAME_WILDCARD)}\z/, "")]
      conditions << {'X-Amz-Algorithm' => algorithm}
      conditions << {'X-Amz-Credential' => credential}
      conditions << {'X-Amz-Date' => date}
      conditions << ["starts-with", "$Content-Type", ""] if will_include_content_type
      conditions << {"bucket" => fog_directory}
      conditions << {"acl" => acl}

      if use_action_status
        conditions << {"success_action_status" => success_action_status}
      else
        conditions << {"success_action_redirect" => success_action_redirect}
      end

      conditions << ["content-length-range", options[:min_file_size], options[:max_file_size]]

      yield conditions if block_given?

      Base64.encode64(
        {
          'expiration' => (Time.now + options[:expiration]).utc.iso8601,
          'conditions' => conditions
        }.to_json
      ).gsub("\n","")
    end

    def signing_key(options = {})
      @date ||= Time.now.utc.strftime("%Y%m%d")
      #AWS Signature Version 4
      kDate    = OpenSSL::HMAC.digest('sha256', "AWS4" + aws_secret_access_key, @date)
      kRegion  = OpenSSL::HMAC.digest('sha256', kDate, region)
      kService = OpenSSL::HMAC.digest('sha256', kRegion, 's3')
      kSigning = OpenSSL::HMAC.digest('sha256', kService, "aws4_request")

      kSigning
    end
  end
end
