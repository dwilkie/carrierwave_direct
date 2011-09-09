Fog.mock!

def fog_directory
  'AWS_FOG_DIRECTORY'
end

connection = ::Fog::Storage.new(
  :aws_access_key_id      => 'AWS_ACCESS_KEY_ID',
  :aws_secret_access_key  => 'AWS_SECRET_ACCESS_KEY',
  :provider               => 'AWS'
)

connection.directories.create(:key => fog_directory)

