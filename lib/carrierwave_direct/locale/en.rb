{
  :en => {
    :errors => {
      :messages => {
        :carrierwave_direct_filename_invalid => lambda {|key, options|
          message = "filename is invalid"
          message << ". Must be #{options[:extension_white_list].to_sentence}" if options[:extension_white_list] && options[:extension_white_list].any?
          message
        }
      }
    }
  }
}

