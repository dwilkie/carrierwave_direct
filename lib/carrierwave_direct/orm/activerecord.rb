# encoding: utf-8

require 'active_record'
require 'carrierwave_direct/validations/active_model'

module CarrierWaveDirect
  module ActiveRecord
    include CarrierWaveDirect::Mount

    def mount_uploader(column, uploader=nil, options={}, &block)
      super

      uploader.instance_eval <<-RUBY, __FILE__, __LINE__+1
        include ActiveModel::Conversion
        extend ActiveModel::Naming
      RUBY

      include CarrierWaveDirect::Validations::ActiveModel

      self.instance_eval <<-RUBY, __FILE__, __LINE__+1
        attr_accessible :key, :remote_#{column}_net_url
      RUBY

      mod = Module.new
      include mod
      mod.class_eval <<-RUBY, __FILE__, __LINE__+1
        def filename_valid?
          if has_#{column}_upload?
            valid?
            column_errors = errors[:#{column}]
            errors.clear
            column_errors.each do |column_error|
              errors.add(:#{column}, column_error)
            end
            errors.empty?
          else
            true
          end
        end
      RUBY
    end
  end
end

ActiveRecord::Base.extend CarrierWaveDirect::ActiveRecord

