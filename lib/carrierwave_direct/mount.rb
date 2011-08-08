module CarrierWaveDirect

  module Mount
    def mount_uploader(column, uploader=nil, options={}, &block)
      super
      uploader.class_eval <<-RUBY, __FILE__, __LINE__+1
        def #{column}; self; end
      RUBY
    end
  end
end

