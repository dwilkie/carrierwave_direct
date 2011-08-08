module UploaderHelpers
  def sample_key(options = {})
    options[:valid] = true unless options[:valid] == false
    options[:valid] &&= !options[:invalid]
    options[:mounted_as] ||= :image
    options[:base] ||= DirectUploader.key(:model_class => options[:subject], :mounted_as => options[:mounted_as])
    if options[:filename]
      filename_parts = options[:filename].split(".")
      options[:extension] = filename_parts.pop if filename_parts.size > 1
      options[:filename] = filename_parts.join(".")
    end
    options[:filename] ||= "filename"
    options[:extension] = options[:extension] ? options[:extension].gsub(".", "") : "jpg"
    key = options[:base].split("/")
    key.pop
    key.pop unless options[:valid]
    key << "#{options[:filename]}.#{options[:extension]}"
    key.join("/")
  end
end

