module CarrierWaveDirect
  module Uploader
    module DirectUrl

      def direct_fog_url(options = {})
        if options[:with_path]
          warn "calling `#direct_for_url` with :with_path is deprecated, please use `#url` instead."
          url
        else
          CarrierWave::Storage::Fog::File.new(self, CarrierWave::Storage::Fog.new(self), nil).public_url
        end
      end

    end
  end
end
