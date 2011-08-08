# encoding: utf-8
require "carrierwave_direct/version"

require "carrierwave"
require "fog"

# TODO: remove active_model dependency...
require "active_model/conversion"
require "active_model/naming"

require "uuid"

module CarrierWaveDirect
  autoload :Uploader, "carrierwave_direct/uploader"
  autoload :Mount, "carrierwave_direct/mount"
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

