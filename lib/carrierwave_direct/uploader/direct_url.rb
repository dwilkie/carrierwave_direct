module CarrierWaveDirect
  module Uploader
    module DirectUrl

      def direct_fog_url(options = {})
        fog_uri = CarrierWave::Storage::Fog::File.new(self, CarrierWave::Storage::Fog.new(self), nil).public_url
        if options[:with_path]
          uri = URI.parse(fog_uri.chomp('/'))
          path = "/#{URI.decode(key)}"
          uri.path += URI.escape(path)
          fog_uri = uri.to_s
        end
        fog_uri
      end

      def asset_host
        # overridden to prevent file uploads to the configured
        # asset host (if any).
      end

    end
  end
end
