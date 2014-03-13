SAMPLE_DATA = {
  :path => "upload_dir/bliind.exe",
  :path_with_special_chars => "uploads/7cf36992-300b-4c54-8f74-c22bd76b69a6/Financial Module - Money Management - What is a Budget and Why is it Important?.pdf",
  :key => "some key",
  :guid => "guid",
  :store_dir => "store_dir",
  :extension_regexp => "(avi)",
  :url => "http://example.com/some_url",
  :expiration => 60,
  :min_file_size => 1024,
  :max_file_size => 10485760,
  :file_url => "http://anyurl.com/any_path/video_dir/filename.avi",
  :mounted_model_name => "Porno",
  :mounted_as => :video,
  :filename => "filename",
  :extension => ".avi",
  :version => :thumb,
  :s3_bucket_url => "https://s3-bucket.s3.amazonaws.com"
}

SAMPLE_DATA.merge!(
  :stored_filename_base => "#{sample(:guid)}/#{sample(:filename)}"
)

SAMPLE_DATA.merge!(
  :stored_filename => "#{sample(:stored_filename_base)}#{sample(:extension)}",
  :stored_version_filename => "#{sample(:stored_filename_base)}_#{sample(:version)}#{sample(:extension)}"
)

SAMPLE_DATA.merge!(
  :s3_key => "#{sample(:store_dir)}/#{sample(:stored_filename)}"
)

SAMPLE_DATA.merge!(
  :s3_file_url => "#{sample(:s3_bucket_url)}/#{sample(:s3_key)}"
)

SAMPLE_DATA.freeze

