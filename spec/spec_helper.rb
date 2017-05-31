# encoding: utf-8

require 'carrierwave_direct'
require 'json'
require 'timecop'

require File.dirname(__FILE__) << '/support/view_helpers' # Catch dependency order

Dir[ File.dirname(__FILE__) << "/support/**/*.rb"].each {|file| require file }

module Rails
  def self.env
    ActiveSupport::StringInquirer.new("test")
  end
end

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

RSpec.configure do |config|
  config.before(:each, :skip_aws_stub => true) do
    @skip_aws_stub = true
  end
  config.before(:each) do
    unless defined?(@skip_aws_stub) && @skip_aws_stub
      allow(CarrierWave::Storage::AWSFile).to receive(:new).and_return(double("AWSFile", :public_url => "url"))
      allow(CarrierWave::Storage::AWS).to receive(:new).and_return(double("AWS", :connection => "AWSconnection"))
    end
  end
end
