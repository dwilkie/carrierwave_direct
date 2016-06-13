module CarrierWaveDirect
  module Uploader
    module DirectUrl

      def direct_fog_url(options = {})
        if options[:with_path]
          url
        else
          CarrierWave::Storage::Fog::File.new(self, CarrierWave::Storage::Fog.new(self), nil).public_url
        end
      end

      def asset_host
        return super if file.respond_to?(:path) && !file.path.blank?
        return super if respond_to?(:has_key?) && has_key?
        nil
      end

    end
  end
end
