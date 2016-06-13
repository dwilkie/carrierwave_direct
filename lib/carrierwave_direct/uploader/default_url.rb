module CarrierWaveDirect
  module Uploader
    module DefaultUrl

      def default_url(*args)
        return unless respond_to?(:has_key?) && has_key?

        fog = CarrierWave::Storage::Fog.new(self)
        CarrierWave::Storage::Fog::File.new(self, fog, key).url
      end

    end
  end
end

