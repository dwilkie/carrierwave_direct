# encoding: utf-8

CarrierWave.configure do |config|
  config.storage = :aws
  config.aws_bucket = 'AWS_BUCKET' # bucket name
  config.aws_acl = 'public-read'
  config.aws_credentials = {
    :access_key_id      => 'AWS_ACCESS_KEY_ID',
    :secret_access_key  => 'AWS_SECRET_ACCESS_KEY',
    :region => 'AWS_REGION'
  }
end

