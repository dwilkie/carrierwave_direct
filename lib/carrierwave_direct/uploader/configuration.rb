# encoding: utf-8

module CarrierWaveDirect

  module Uploader
    module Configuration
      extend ActiveSupport::Concern

      included do
        add_config :validate_is_attached
        add_config :validate_is_uploaded
        add_config :validate_unique_filename
        add_config :validate_filename_format
        add_config :validate_remote_net_url_format
        reset_direct_config
      end

      module ClassMethods
        def reset_direct_config
          configure do |config|
            config.validate_is_attached = false
            config.validate_is_uploaded = false
            config.validate_unique_filename = true
            config.validate_filename_format = true
            config.validate_remote_net_url_format = true
          end
        end
      end
    end
  end
end

