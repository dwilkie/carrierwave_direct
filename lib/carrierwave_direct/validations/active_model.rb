# encoding: utf-8

require 'active_model/validator'
require 'active_support/concern'

module CarrierWaveDirect

  module Validations
    module ActiveModel
      extend ActiveSupport::Concern

      class UniqueFilenameValidator < ::ActiveModel::EachValidator
        def validate_each(record, attribute, value)
          if record.new_record? && record.errors[attribute].empty? && (record.send("has_#{attribute}_upload?") || record.send("has_remote_#{attribute}_net_url?"))
            if record.class.where(attribute => record.send(attribute).filename).exists?
              record.errors.add(attribute, :carrierwave_direct_filename_taken)
            end
          end
        end
      end

      class FilenameFormatValidator < ::ActiveModel::EachValidator
        def validate_each(record, attribute, value)
          if record.new_record? && (record.key !~ record.send(attribute).key_regexp)
            record.errors.add(
              attribute,
              :carrierwave_direct_filename_invalid,
              :extension_white_list => record.send(attribute).extension_white_list
            )
          end
        end
      end

      module HelperMethods

        ##
        # Makes the record invalid if the filename already exists
        #
        # Accepts the usual parameters for validations in Rails (:if, :unless, etc...)
        #
        # === Note
        #
        # Set this key in your translations file for I18n:
        #
        #     carrierwave_direct:
        #       errors:
        #         filename_taken: 'Here be an error message'
        #
        def validates_filename_uniqueness_of(*attr_names)
          validates_with UniqueFilenameValidator, _merge_attributes(attr_names)
        end

        def validates_filename_format_of(*attr_names)
          validates_with FilenameFormatValidator, _merge_attributes(attr_names)
        end

      end

      included do
        extend HelperMethods
        include HelperMethods
      end
    end
  end
end

Dir[File.dirname(__FILE__) << "/../locale/*.*"].each {|file| I18n.load_path << file }

