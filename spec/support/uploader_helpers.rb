module UploaderHelpers
  include CarrierWaveDirect::Test::Helpers

  def sample_key(options = {})
    super(DirectUploader, options)
  end
end

