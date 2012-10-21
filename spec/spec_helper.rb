# encoding: utf-8

require 'carrierwave_direct'
require 'json'
require 'timecop'

require File.dirname(__FILE__) << '/support/view_helpers' # Catch dependency order

Dir[ File.dirname(__FILE__) << "/support/**/*.rb"].each {|file| require file }

RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true
end
