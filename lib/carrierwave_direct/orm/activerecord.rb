# encoding: utf-8

require 'active_record'

module CarrierWaveDirect
  module ActiveRecord
    include CarrierWaveDirect::Mount
  end
end

ActiveRecord::Base.extend CarrierWaveDirect::ActiveRecord

