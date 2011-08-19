# encoding: utf-8

module CarrierWaveDirect
  module Uploader
    extend ActiveSupport::Concern

    included do
      attr_accessor :success_action_redirect

      fog_credentials.keys.each do |key|
        define_method(key) do
          fog_credentials[key]
        end
      end
    end

    S3_FILENAME_WILDCARD = "${filename}"

    module ClassMethods
      include ActiveModel::Conversion
      extend ActiveModel::Naming

      def upload_expiration
        36000
      end

      def max_file_size
        5242880
      end

      def store_dir(model_class, mounted_as)
        "uploads/#{model_class.to_s.underscore}/#{mounted_as}"
      end

      def allowed_file_types(options = {})
        file_types = %w(jpg jpeg gif png)
        if options[:as] == :sentence
          file_types.to_sentence
        elsif options[:as] == :regexp_string
          "\\.(#{file_types.join("|")})"
        else
          file_types
        end
      end

      def key(options = {})
        options[:store_dir] ||= store_dir(options[:model_class], options[:mounted_as])
        options[:guid] ||= UUID.generate
        options[:filename] ||= S3_FILENAME_WILDCARD
        key_path = "#{options[:store_dir]}/#{options[:guid]}/#{options[:filename]}"
        if options[:as] == :regexp
          key_parts = key_path.split("/")
          key_parts.pop
          key_parts.pop
          key_path = key_parts.join("/")
          key_path = /\A#{key_path}\/[a-f\d\-]+\/.+#{allowed_file_types(:as => :regexp_string)}\z/
        end
        key_path
      end
    end # ClassMethods

    module InstanceMethods
      def direct_fog_url(options = {})
        fog_uri = CarrierWave::Storage::Fog::File.new(self, nil, nil).public_url
        if options[:with_path]
          uri = URI.parse(fog_uri)
          path = "/#{key}"
          uri.path = path
          fog_uri = uri.to_s
        end
        fog_uri
      end

      def key=(k)
        @key = k
        update_version_keys(:with => @key)
      end

      def key
        @key ||= self.class.key(:store_dir => store_dir)
      end

      def has_key?
        @key.present? && !(@key =~ /#{Regexp.escape(S3_FILENAME_WILDCARD)}\z/)
      end

      def persisted?
        false
      end

      def acl
        s3_access_policy.to_s.gsub('_', '-')
      end

      def policy(options = {})
        options[:expiration] ||= self.class.upload_expiration
        options[:max_file_size] ||= self.class.max_file_size

        Base64.encode64(
          {
            'expiration' => Time.now + options[:expiration],
            'conditions' => [
              ["starts-with", "$utf8", ""],
              ["starts-with", "$key", store_dir],
              {"bucket" => fog_directory},
              {"acl" => acl},
              {"success_action_redirect" => success_action_redirect},
              ["content-length-range", 1, options[:max_file_size]]
            ]
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

      def store_dir
        self.class.store_dir(model.class, mounted_as)
      end

      def filename
        unless has_key?
          # Use the attached models remote url to generate a new key otherwise raise an error
          remote_url = model.send("remote_#{mounted_as}_url")
          remote_url ? key_from_file(remote_url.split("/").pop) : raise(
            ArgumentError,
            "could not generate filename because the uploader has no key and the #{model.class} has no remote_#{mounted_as}_url"
          )
        end

        key_path = key.split("/")
        filename_parts = []
        filename_parts.unshift(key_path.pop)
        filename_parts.unshift(key_path.pop)
        File.join(filename_parts)
      end

      # Add a white list of extensions which are allowed to be uploaded.
      def extension_white_list
        self.class.allowed_file_types
      end

      private

      def key_from_file(fname)
        self.key = self.class.key(:store_dir => store_dir, :filename => fname)
      end

      # Update the versions to use this key
      def update_version_keys(options)
        versions.each do |name, uploader|
          uploader.key = options[:with]
        end
      end
    end # InstanceMethods

    private

    # Put the version name at the end of the filename since the guid is also stored
    # e.g. guid/filename_thumb.jpg instead of CarrierWave's default: thumb_guid/filename.jpg
    def full_filename(for_file)
      extname = File.extname(for_file)
      [for_file.chomp(extname), version_name].compact.join('_') << extname
    end
  end
end

