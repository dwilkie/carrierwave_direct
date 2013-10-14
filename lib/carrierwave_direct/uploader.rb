# encoding: utf-8

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

    def acl
      fog_public ? 'public-read' : 'private'
    end

    def policy(options = {})
      options[:expiration] ||= upload_expiration
      options[:min_file_size] ||= min_file_size
      options[:max_file_size] ||= max_file_size

      conditions = [
        ["starts-with", "$utf8", ""],
        ["starts-with", "$key", blank_key.sub(/#{Regexp.escape(FILENAME_WILDCARD)}\z/, "")]
      ]

      conditions << ["starts-with", "$Content-Type", ""] if will_include_content_type
      conditions << {"bucket" => fog_directory}
      conditions << {"acl" => acl}

      if use_action_status
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

    def url_scheme_white_list
      nil
    end

    def persisted?
      false
    end

    # We must cache the generated blank_key in order for the form data and
    # generated policy to match
    def blank_key
      @blank_key ||= "#{store_dir}/#{generate_guid}/#{FILENAME_WILDCARD}"
    end

    # If the filename is not set, use the path for the key
    # Note: Cacheing is not done here on purpose.  We let
    # carrierwave worry about updating path and filename changes.
    def key
      filename ? "#{store_dir}/#{filename}" : path
    end

    # Key is used to set the guid and filename explicitly.
    # After these are we refresh the uploaders file reference
    # in order to reflect the key change
    #
    # Note the store_dir must match between uploaders when setting
    # the key.
    def key=(new_key)
      return if new_key.blank?

      key_parts = new_key.split("/")

      @filename = key_parts.pop
      set_cached_guid(key_parts.pop)

      refresh_fog_file

      key
    end

    # Generate a new guid if no file has been stored or if
    # a new file has been cached; otherwise, use the stored
    # identifier to get the guid
    def guid
      storage_identifier = model[mounted_as]

      if storage_identifier.blank? || cached?
        get_or_set_cached_guid(generate_guid)
      else
        get_or_set_cached_guid(storage_identifier.split("/").first)
      end
    end

    # Make sure to store the guid with the filename in the database
    def filename
     "#{guid}/#{@filename}" if @filename
    end

    def has_key?
      !key.nil?
    end

    def key_regexp
      /\A#{store_dir}\/[a-f\d\-]+\/.+\.(?i)#{extension_regexp}(?-i)\z/
    end

    def extension_regexp
      allowed_file_types = extension_white_list
      extension_regexp = allowed_file_types.present? && allowed_file_types.any? ?  "(#{allowed_file_types.join("|")})" : "\\w+"
    end

    private

    # Guid is cached as an instance variable in the model
    # in order to make sure that all verions get the same guid.
    def get_or_set_cached_guid(value)
      get_cached_guid || set_cached_guid(value)
    end

    def set_cached_guid(value)
      model.instance_variable_set(guid_instance_variable, value)
    end

    def get_cached_guid
      model.instance_variable_get(guid_instance_variable)
    end

    def generate_guid
      UUIDTools::UUID.random_create
    end

    def guid_instance_variable
      :"@#{mounted_as}_guid"
    end

    def refresh_fog_file
      @file = CarrierWave::Storage::Fog::File.new(self, storage, self.key)
    end

    # Put the version name at the end of the filename since the guid is also stored
    # e.g. guid/filename_thumb.jpg instead of CarrierWave's default: thumb_guid/filename.jpg
    def full_filename(for_file)
      extname = File.extname(for_file)
      [for_file.chomp(extname), version_name].compact.join('_') << extname
    end
  end
end
