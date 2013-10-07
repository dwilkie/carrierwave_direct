# encoding: utf-8

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

    def direct_fog_url(options = {})
      fog_uri = CarrierWave::Storage::Fog::File.new(self, CarrierWave::Storage::Fog.new(self), nil).public_url
      if options[:with_path]
        uri = URI.parse(fog_uri.chomp('/'))
        path = "/#{key}"
        uri.path += URI.escape(path)
        fog_uri = uri.to_s
      end
      fog_uri
    end

    def guid
      UUIDTools::UUID.random_create
    end

    def key=(k)
      @key = k
      update_version_keys(:with => @key)
    end

    def key
      return @key if @key.present?
      if present?
        self.key = URI.parse(URI.encode(url, " []+()")).path[1 .. -1] # explicitly set key
      else
        @key = "#{store_dir}/#{guid}/#{FILENAME_WILDCARD}"
      end
      @key
    end

    def has_key?
      key !~ /#{Regexp.escape(FILENAME_WILDCARD)}\z/
    end

    def acl
      fog_public ? 'public-read' : 'private'
    end

    def content_type
      default = self.class.default_content_type || self.class.will_include_content_type

      default.is_a?(String) ? default : 'binary/octet-stream'
    end

    def content_types
      types = self.class.allowed_content_types

      return types if types.is_a? Array
      %w(application/atom+xml application/ecmascript application/json
         application/javascript application/octet-stream application/ogg
         application/pdf application/postscript application/rss+xml
         application/font-woff application/xhtml+xml application/xml
         application/xml-dtd application/zip application/gzip audio/basic
         audio/mp4 audio/mpeg audio/ogg audio/vorbis audio/vnd.rn-realaudio
         audio/vnd.wave audio/webm image/gif image/jpeg image/pjpeg
         image/png image/svg+xml image/tiff text/cmd text/css text/csv
         text/html text/javascript text/plain text/vcard text/xml video/mpeg
         video/mp4 video/ogg video/quicktime video/webm video/x-matroska
         video/x-ms-wmv video/x-flv)
    end

    def policy(options = {})
      options[:expiration] ||= self.class.upload_expiration
      options[:min_file_size] ||= self.class.min_file_size
      options[:max_file_size] ||= self.class.max_file_size

      conditions = [
        ["starts-with", "$utf8", ""],
        ["starts-with", "$key", key.sub(/#{Regexp.escape(FILENAME_WILDCARD)}\z/, "")],
        ["starts-with", "$Content-Type",""]
      ]
      conditions << {"bucket" => fog_directory}
      conditions << {"acl" => acl}

      if self.class.use_action_status
        conditions << {"success_action_status" => success_action_status}
      else
        conditions << {"success_action_redirect" => success_action_redirect}
      end

      conditions << ["content-length-range", options[:min_file_size], options[:max_file_size]]

      Base64.encode64(
        {
          'expiration' => Time.now.utc + options[:expiration],
          'conditions' => conditions
        }.to_json
      ).gsub("\n","")
    end

    def signature
      Base64.encode64(
        OpenSSL::HMAC.digest(
          OpenSSL::Digest::Digest.new('sha1'),
          aws_secret_access_key, policy
        )
      ).gsub("\n","")
    end

    def persisted?
      false
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

    def key_regexp
      /\A#{store_dir}\/[a-f\d\-]+\/.+\.(?i)#{extension_regexp}(?-i)\z/
    end

    def extension_regexp
      allowed_file_types = extension_white_list
      extension_regexp = allowed_file_types.present? && allowed_file_types.any? ?  "(#{allowed_file_types.join("|")})" : "\\w+"
    end

    def url_scheme_white_list
      nil
    end

    private

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
  end
end
