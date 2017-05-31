module CarrierWaveDirect
  module Uploader
    module DirectUrl

      def direct_aws_url(options = {})
        if options[:with_path]
          url
        else
          CarrierWave::Storage::AWSFile.new(self, CarrierWave::Storage::AWS.new(self).connection, nil).public_url
        end
      end

    end
  end
end
