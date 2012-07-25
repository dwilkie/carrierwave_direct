# encoding: utf-8

module CarrierWaveDirect

  module Mount
    def mount_uploader(column, uploader=nil, options={}, &block)
      super

      # Don't go further unless the class included CarrierWaveDirect::Uploader
      return unless uploader.ancestors.include?(CarrierWaveDirect::Uploader)

      uploader.class_eval <<-RUBY, __FILE__, __LINE__+1
        def #{column}; self; end
      RUBY

      self.instance_eval <<-RUBY, __FILE__, __LINE__+1
        attr_accessor :remote_#{column}_net_url
      RUBY

      mod = Module.new
      include mod
      mod.class_eval <<-RUBY, __FILE__, __LINE__+1

        def key
          send(:#{column}).key
        end

        def key=(k)
          send(:#{column}).key = k
        end

        def has_#{column}_upload?
          send(:#{column}).has_key?
        end

        def has_remote_#{column}_net_url?
          send(:remote_#{column}_net_url).present?
        end
      RUBY
    end
  end
end

