# encoding: utf-8

module CarrierWaveDirect
  module Test
    module Helpers
      # Example usage:

      # sample_key(ImageUploader, :base => "store_dir/guid/${filename}")
      # => "store_dir/guid/filename.extension"

      # sample_key(ImageUploader, :subject => Porno, :mounted_asnted_as => :video)
      # => "uploads/porno/video/guid/filename.extension"

      # sample_key(ImageUploader, :subject => Porno, :mounted_as => :video, :filename => :hardcore, :extension => :avi)
      # => "uploads/porno/video/guid/hardcore.avi"

      # sample_key(ImageUploader, :subject => Porno, :mounted_as => :video, :valid => false)
      # => "uploads/porno/video/filename.extension"

      def sample_key(uploader, options = {})
        options[:valid] = true unless options[:valid] == false
        options[:valid] &&= !options[:invalid]
        options[:base] ||= uploader.key(options.dup)
        if options[:filename]
          filename_parts = options[:filename].split(".")
          options[:extension] = filename_parts.pop if filename_parts.size > 1
          options[:filename] = filename_parts.join(".")
        end
        options[:filename] ||= "filename"
        options[:extension] = options[:extension] ? options[:extension].gsub(".", "") : (uploader.allowed_file_types.first || "extension")
        key = options[:base].split("/")
        key.pop
        key.pop unless options[:valid]
        key << "#{options[:filename]}.#{options[:extension]}"
        key.join("/")
      end
    end
  end
end

