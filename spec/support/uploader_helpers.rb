module UploaderHelpers
  include CarrierWaveDirect::Test::Helpers

  def sample_key(options = {})
    super(MountedClass.new.video, options)
  end
end

