class MountedClass
  extend CarrierWave::Mount
  extend CarrierWaveDirect::Mount
  mount_uploader :video, DirectUploader
end

