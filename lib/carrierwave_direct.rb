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

    CarrierWave::Uploader::Base.send(:include, Configuration)
  end

  module Test
    autoload :Helpers, 'carrierwave_direct/test/helpers'
    autoload :CapybaraHelpers, 'carrierwave_direct/test/capybara_helpers'
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

      initializer "carrierwave_direct.action_view" do
        ActiveSupport.on_load :action_view do
          require 'carrierwave_direct/form_builder'
          require 'carrierwave_direct/action_view_extensions/form_helper'
        end
      end
    end
  end
end

