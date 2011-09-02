# CarrierWaveDirect

[CarrierWave](https://github.com/jnicklas/carrierwave) is a great way to upload files from Ruby applications, but since processing and saving is done in-process, it doesn't scale well. A better way is to upload your files directly then handle the processing and saving in a background process.

[CarrierWaveDirect](https://github.com/dwilkie/carrierwave_direct) works on top of [CarrierWave](https://github.com/jnicklas/carrierwave) and provides a simple way to achieve this.

