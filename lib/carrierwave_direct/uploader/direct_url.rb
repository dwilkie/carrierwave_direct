module CarrierWaveDirect
  module Uploader
    module DirectUrl

      def direct_fog_url(options = {})
        if options[:with_path]
          url
        else
          CarrierWave::Storage::AWSFile.new(self, CarrierWave::Storage::AWS.new(self), nil).public_url
        end
      end

    end
  end
end
