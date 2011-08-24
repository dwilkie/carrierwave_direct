# encoding: utf-8

require 'active_record'
require 'carrierwave_direct/validations/active_model'

module CarrierWaveDirect
  module ActiveRecord
    include CarrierWaveDirect::Mount

    def mount_uploader(column, uploader=nil, options={}, &block)
      super

      include CarrierWaveDirect::Validations::ActiveModel

      self.instance_eval <<-RUBY, __FILE__, __LINE__+1
        attr_accessible :key, :remote_#{column}_net_url
      RUBY
    end
  end
end

ActiveRecord::Base.extend CarrierWaveDirect::ActiveRecord

