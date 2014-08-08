# encoding: utf-8

require 'carrierwave_direct'
require 'json'
require 'timecop'

require File.dirname(__FILE__) << '/support/view_helpers' # Catch dependency order

Dir[ File.dirname(__FILE__) << "/support/**/*.rb"].each {|file| require file }

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = [:expect, :should]
  end
end

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.syntax = [:expect, :should]
  end
end
