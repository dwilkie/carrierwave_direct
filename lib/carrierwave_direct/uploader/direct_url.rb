module CarrierWaveDirect
  module Uploader
    module DirectUrl

      def direct_fog_url(options = {})
        fog_uri = CarrierWave::Storage::Fog::File.new(self, CarrierWave::Storage::Fog.new(self), nil).public_url
        if options[:with_path]
          fog_uri = fog_uri.chomp('/')
          path = URI.escape("/#{key}")
          fog_uri = "#{fog_uri}#{path}"
        end
        fog_uri
      end

    end
  end
end
