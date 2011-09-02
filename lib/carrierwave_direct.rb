# encoding: utf-8
require "carrierwave_direct/version"

require "carrierwave"
require "fog"
require "uuid"

module CarrierWaveDirect
  autoload :Uploader, "carrierwave_direct/uploader"
  autoload :Mount, "carrierwave_direct/mount"

  module Uploader
    autoload :Configuration, 'carrierwave_direct/uploader/configuration'
  end

  module Test
    autoload :Helpers, 'carrierwave_direct/test/helpers'
  end
end

if defined?(Rails)
  module CarrierWaveDirect
    class Railtie < Rails::Railtie

      initializer "carrierwave_direct.active_record" do
        ActiveSupport.on_load :active_record do
          require 'carrierwave_direct/orm/activerecord'
        end
      end
    end
  end
end

