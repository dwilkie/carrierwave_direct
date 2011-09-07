# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "carrierwave_direct/version"

Gem::Specification.new do |s|
  s.name        = "carrierwave_direct"
  s.version     = CarrierwaveDirect::VERSION
  s.authors     = ["David Wilkie"]
  s.email       = ["dwilkie@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Upload direct to S3 using CarrierWave}
  s.description = %q{Process your uploads in the background by uploading directly to S3}

  s.rubyforge_project = "carrierwave_direct"

  s.add_dependency "carrierwave"
  s.add_dependency "uuid"
  s.add_dependency "fog"

  s.add_development_dependency "rspec"
  s.add_development_dependency "timecop"
  s.add_development_dependency "rails"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "capybara"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end

