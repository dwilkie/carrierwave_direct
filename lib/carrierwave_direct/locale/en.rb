# encoding: utf-8

{
  :en => {
    :errors => {
      :messages => {
        :carrierwave_direct_filename_invalid => lambda {|key, options|
          message = "is invalid"
          message << ". Allowed file types are #{options[:extension_white_list].to_sentence}" if options[:extension_white_list] && options[:extension_white_list].any?
          message
        },
        :carrierwave_direct_remote_net_url_invalid => lambda {|key, options|
          message = "is invalid"
          message << ". Allowed file types are #{options[:extension_white_list].to_sentence}" if options[:extension_white_list] && options[:extension_white_list].any?
          message << ". Allowed url schemes are #{options[:url_scheme_white_list].to_sentence}" if options[:url_scheme_white_list] && options[:url_scheme_white_list].any?
          message
        }
      }
    }
  }
}

