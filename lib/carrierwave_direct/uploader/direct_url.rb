module CarrierWaveDirect
  module Uploader
    module DirectUrl

      def direct_fog_url(options = {})
        if fog_public
          fog_public_url(options[:with_path])
        else
          fog_private_url(options[:with_path])
        end
      end

      private

      def fog_public_url(with_path)
        base_url = CarrierWave::Storage::Fog::File.new(self, CarrierWave::Storage::Fog.new(self), nil).public_url
        if with_path
          base_url + key
        else
          base_url
        end
      end

      def fog_private_url(with_path)
        base_url = CarrierWave::Storage::Fog::File.new(self, CarrierWave::Storage::Fog.new(self), nil).public_url
        if with_path
          limited_url(key)
        else
          base_url
        end
      end

      def limited_url(key)
        local_file = local_directory.files.new(key: key)
        expire_at = ::Fog::Time.now + fog_authenticated_url_expiration
        local_file.url(expire_at)
      end

      def local_directory
        connection = ::Fog::Storage.new(fog_credentials)
        connection.directories.new(key: fog_directory)
      end

    end
  end
end
