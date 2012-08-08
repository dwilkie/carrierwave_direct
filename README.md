# CarrierWaveDirect

[![Build Status](https://secure.travis-ci.org/dwilkie/carrierwave_direct.png)](http://travis-ci.org/dwilkie/carrierwave_direct)

[CarrierWave](https://github.com/jnicklas/carrierwave) is a great way to upload files from Ruby applications, but since processing and saving is done in-process, it doesn't scale well. A better way is to upload your files directly then handle the processing and saving in a background process.

[CarrierWaveDirect](https://github.com/dwilkie/carrierwave_direct) works on top of [CarrierWave](https://github.com/jnicklas/carrierwave) and provides a simple way to achieve this.

## Compatibility

Right now, CarrierWaveDirect works with [Amazon S3](http://aws.amazon.com/s3/). Adding support for [Google Storage for Developers](http://code.google.com/apis/storage/) should be fairly straight forward since the direct upload form is essentially the same. Please see the contributing section if you would like support for Google Storage for Developers or any other service that provides direct upload capabilities.

Please be aware that this gem (and S3 in general) only support single file uploads. If you want to upload multiple files simultaneously you'll have to use a javascript or flash uploader.

## Information

More information, and how-tos [available on the wiki](https://github.com/dwilkie/carrierwave_direct/wiki)

## Installation

Install the latest release:

    gem install carrierwave_direct

In Rails, add it to your Gemfile:

    gem 'carrierwave_direct'

Note that CarrierWaveDirect is not compatible with Rails 2.

## Getting Started

Please read the [CarrierWave readme](https://github.com/jnicklas/carrierwave) first

CarrierWaveDirect works with [fog](https://github.com/geemus/fog) so make sure you have [CarrierWave](https://github.com/jnicklas/carrierwave) set up and initialized with your fog credentials, for example:

    CarrierWave.configure do |config|
      config.fog_credentials = {
        :provider               => 'AWS',       # required
        :aws_access_key_id      => 'xxx',       # required
        :aws_secret_access_key  => 'yyy',       # required
        :region                 => 'eu-west-1'  # optional, defaults to 'us-east-1'
      }
      config.fog_directory  = 'name_of_directory'                     # required
      config.fog_host       = 'https://assets.example.com'            # optional, defaults to nil
      config.fog_public     = false                                   # optional, defaults to true
      config.fog_attributes = {'Cache-Control'=>'max-age=315576000'}  # optional, defaults to {}
    end

If you haven't already done so generate an uploader

    rails generate uploader Avatar

this should give you a file in:

    app/uploaders/avatar_uploader.rb

Check out this file for some hints on how you can customize your uploader. It should look something like this:

    class AvatarUploader < CarrierWave::Uploader::Base
      storage :file
    end

Remove the line `storage :file` and replace it with `include CarrierWaveDirect::Uploader` so it should look something like:

    class AvatarUploader < CarrierWave::Uploader::Base
      include CarrierWaveDirect::Uploader
    end

This adds the extra functionality for direct uploading.

Finally, remove the `store_dir` method in order to default CarrierWaveDirect to its own storage directory.

If you're *not* using Rails you can generate a direct upload form to S3 similar to [this example](http://doc.s3.amazonaws.com/proposals/post.html#A_Sample_Form)) by making use of the CarrierWaveDirect helper methods.

### Sinatra

Here is an example using Sinatra and Haml

    # uploader_test.rb

    CarrierWave.configure do |config|
      config.fog_credentials = {
        :provider               => 'AWS',
        :aws_access_key_id      => ENV['AWS_ACCESS_KEY_ID'],
        :aws_secret_access_key  => ENV['AWS_SECRET_ACCESS_KEY']
      }
      config.fog_directory  = ENV['AWS_FOG_DIRECTORY'] # bucket name
    end

    class ImageUploader < CarrierWave::Uploader::Base
      include CarrierWaveDirect::Uploader
    end

    class UploaderTest < Sinatra::Base
      get "/" do
        @uploader = ImageUploader.new
        @uploader.success_action_redirect = request.url
        haml :index
      end
    end

    # index.haml

    %form{:action => @uploader.direct_fog_url, :method => "post", :enctype => "multipart/form-data"}
      %input{:name => "utf8", :type => "hidden"}
      %input{:type => "hidden", :name => "key", :value => @uploader.key}
      %input{:type => "hidden", :name => "AWSAccessKeyId", :value => @uploader.aws_access_key_id}
      %input{:type => "hidden", :name => "acl", :value => @uploader.acl}
      %input{:type => "hidden", :name => "success_action_redirect", :value => @uploader.success_action_redirect}
      %input{:type => "hidden", :name => "policy", :value => @uploader.policy}
      %input{:type => "hidden", :name => "signature", :value => @uploader.signature}
      %input{:name => "file", :type => "file"}
      %input{:type => "submit", :value => "Upload to S3"}

### Rails

If you *are* using Rails and you've mounted your uploader like this:

    class User < ActiveRecord::Base
      mount_uploader :avatar, AvatarUploader
    end

things just got a whole lot easier. You can generate a direct upload form like this:

    class AvatarController < ApplicationController
      def new
        @uploader = User.new.avatar
        @uploader.success_action_redirect = new_user_url
      end
    end

    <%= direct_upload_form_for @uploader do |f| %>
      <%= f.file_field :avatar %>
      <%= f.submit %>
    <% end %>

You can also pass html options like this:

    <%= direct_upload_form_for @uploader, :html => { :target => "_blank_iframe" } do |f| %>
      <%= f.file_field :avatar %>
      <%= f.submit %>
    <% end %>

Note if `User` is not an ActiveRecord object e.g.

    class User
      mount_uploader :avatar, AvatarUploader
    end

you can still use the form helper by including the ActiveModel modules your uploader:

    class AvatarUploader < CarrierWave::Uploader::Base
      include CarrierWaveDirect::Uploader

      include ActiveModel::Conversion
      extend ActiveModel::Naming
    end

Note if you're using Rails 3.0.x you'll also need to disable forgery protection

    # config/application.rb
    config.action_controller.allow_forgery_protection = false

Once you've uploaded your file directly to the cloud you'll probably need a way to reference it with an ORM and process it.

## Processing and referencing files in a background process

Processing and saving file uploads are typically long running tasks and should be done in a background process. CarrierWaveDirect gives you a few methods to help you do this with your favorite background processor such as [DelayedJob](https://github.com/collectiveidea/delayed_job) or [Resque](https://github.com/defunkt/resque).

If your upload was successful then you will be redirected to the `success_action_redirect` url you specified in your uploader. S3 replies with a redirect like this: `http://example.com?bucket=your_fog_directory&key=uploads%2Fguid%2Ffile.ext&etag=%22d41d8cd98f00b204e9800998ecf8427%22`

The `key` is the most important piece of information as we can use it for validating the file extension, downloading the file from S3, processing it and re-uploading it.

If you're using ActiveRecord, CarrierWaveDirect will by default validate the file extension based off your `extension_white_list` in your uploader. See the [CarrierWave readme](https://github.com/jnicklas/carrierwave) for more info. You can then use the helper `filename_valid?` to check if the filename is valid. e.g.

    class UsersController < ApplicationController
      def new
        @user = User.new(params)
        unless @user.filename_valid?
          flash[:error] = @user.errors.full_messages.to_sentence
          redirect_to new_avatar_path
        end
      end
    end

CarrierWaveDirect automatically gives you an accessible `key` attribute in your mounted model when using ActiveRecord. You can use this to put a hidden field for the `key` into your model's form.

    <%= form_for @user do |f| %>
      <%= f.hidden_field :key %>
      <%= f.label :email %>
      <%= f.text_field :email %>
      <%= f.submit %>
    <% end %>

then in your controller you can do something like this:

    def create
      @user = User.new(params[:user])
      if @user.save_and_process_avatar
        flash[:notice] = "User being created"
        redirect_to :action => :index
      else
        render :new
      end
    end

### Background processing

Now that the basic building blocks are in place you can process and save your avatar in the background. This example uses [Resque](https://github.com/defunkt/resque) but the same logic could be applied to [DelayedJob](https://github.com/collectiveidea/delayed_job) or any other background processor.

    class User < ActiveRecord::Base
      def save_and_process_avatar(options = {})
        if options[:now]
          self.remote_avatar_url = avatar.direct_fog_url(:with_path => true)
          save
        else
          Resque.enqueue(AvatarProcessor, attributes)
        end
      end
    end

    class AvatarProcessor
      @queue = :avatar_processor_queue

      def self.perform(attributes)
        user = User.new(attributes)
        user.save_and_process_avatar(:now => true)
      end
    end

The method `self.remote_avatar_url=` from [CarrierWave](https://github.com/jnicklas/carrierwave) downloads the avatar from S3 and processes it. `save` then re-uploads the processed avatar to to S3

## Uploading from a remote location

Your users may find it convenient to upload a file from a location on the Internet via a URL. CarrierWaveDirect gives you another accessor to achieve this.

    <%= form_for @user do |f| %>
      <%= f.hidden_field :key %>
      <% unless @user.has_avatar_upload? %>
        <%= f.label :remote_avatar_net_url %>
        <%= f.text_field :remote_avatar_net_url %>
      <%= f.submit %>
    <% end %>


    class User < ActiveRecord::Base
      def save_and_process_avatar(options = {})
        if options[:now]
          self.remote_avatar_url = has_remote_avatar_net_url? ? remote_avatar_net_url : avatar.direct_fog_url(:with_path => true)
          save
        else
          Resque.enqueue(AvatarProcessor, attributes)
        end
      end
    end

The methods `has_avatar_upload?`, `remote_avatar_net_url` and `has_remote_avatar_net_url?` are automatically added to your mounted model

## Validations

Along with validating the extension of the filename, CarrierWaveDirect also gives you some other validations:

      validates :avatar :is_uploaded => true

Validates that your mounted model has an avatar uploaded from file or specified by remote url. It does not check that an your mounted model actually has a valid avatar after the download has taken place. Turned *off* by default

      validates :avatar, :is_attached => true

Validates that your mounted model has an avatar attached. This checks whether there is an actual avatar attached to the mounted model after downloading. Turned *off* by default

      validates :avatar, :filename_uniqueness => true

Validates that the filename in the database is unique. Turned *on* by default

      validates :avatar :filename_format => true

Validates that the uploaded filename is valid. As well as validating the extension against the `extension_white_list` it also validates that the `upload_dir` is correct. Turned *on* by default

      validates :avatar :remote_net_url_format => true

Validates that the remote net url is valid. As well as validating the extension against the `extension_white_list` it also validates that url is valid and has only the schemes specified in the `url_scheme_whitelist`. Turned *on* by default

## Configuration

As well as the built in validations CarrierWaveDirect provides, some validations, such as max file size and upload expiration can be performed on the S3 side.

    CarrierWave.configure do |config|
      config.validate_is_attached = true             # defaults to false
      config.validate_is_uploaded = true             # defaults to false
      config.validate_unique_filename = false        # defaults to true
      config.validate_filename_format = false        # defaults to true
      config.validate_remote_net_url_format = false  # defaults to true

      config.max_file_size     = 10.megabytes        # defaults to 5.megabytes
      config.upload_expiration = 1.hour              # defaults to 10.hours
    end

## Testing with CarrierWaveDirect

CarrierWaveDirect provides a couple of helpers to help with integration and unit testing. You don't want to contact the Internet during your tests as this is slow, expensive and unreliable. You should first put fog into mock mode by doing something like this.

    Fog.mock!

    def fog_directory
      ENV['AWS_FOG_DIRECTORY']
    end

    connection = ::Fog::Storage.new(
      :aws_access_key_id      => ENV['AWS_ACCESS_KEY_ID'],
      :aws_secret_access_key  => ENV['AWS_SECRET_ACCESS_KEY'],
      :provider               => 'AWS'
    )

    connection.directories.create(:key => fog_directory)

### Using Capybara

If your using Capybara with Cucumber or RSpec, CarrierWaveDirect gives you a few useful helpers. To get the Capybara helpers, include the module into your test file or helper

    describe AvatarUploadSpec
      include CarrierWaveDirect::Test::CapybaraHelpers
    end

To attach a file to the direct upload form you can use

    attach_file_for_direct_upload('path/to/file.ext')

To simulate a successful upload and redirect to S3 you can use

    upload_directly(AvatarUploader.new, "Upload to S3")

This will click the Upload to S3 button on the form and redirect you to the `success_action_redirect` url (in the form) with a sample response from S3

To simulate an unsuccessful upload you can pass `:success => false` and you'll remain on the upload page e.g.

    upload_directly(AvatarUploader.new, "Upload to S3", :success => false)

You can also use `find_key` and `find_upload_path` to get the key and upload path from the form

### Unit tests

If your mounted model validates a file is uploaded you might want to make use of the `sample_key` method

    include CarrierWaveDirect::Test::Helpers

    Factory.define :user |f|
      f.email "some1@example.com"
      f.key { sample_key(AvatarUploader.new) }
    end

This will return a valid key based off your `upload_dir` and your `extension_white_list`

### Faking a background download

If you wanted to fake a download in the background you could do something like this

      uploader = AvatarUploader.new

      upload_path = find_upload_path
      redirect_key = sample_key(:base => find_key, :filename => File.basename(upload_path))

      uploader.key = redirect_key
      download_url = uploader.direct_fog_url(:with_path => true)

      # Register the download url and return the uploaded file in the body
      FakeWeb.register_uri(:get, download_url, :body => File.open(upload_path))

## i18n

The Active Record validations use the Rails i18n framework. Add these keys to your translations file:

    en:
      errors:
        messages:
          carrierwave_direct_filename_taken: filename was already taken
          carrierwave_direct_upload_missing: upload is missing
          carrierwave_direct_attachment_missing: attachment is missing
          carrierwave_direct_filename_invalid: is invalid. Allowed file types are %{extension_white_list}
          carrierwave_direct_remote_net_url_invalid: is invalid. Allowed file types are %{extension_white_list}. Allowed url schemes are %{url_scheme_white_list}

## Caveats

Don't name your string column `file`. It will result in a stack level too deep exception. See [this issue](https://github.com/dwilkie/carrierwave_direct/issues/10) for more info

## Contributing to CarrierWaveDirect

Pull requests are very welcome. Before submitting a pull request, please make sure that your changes are well tested.

    gem install bundler
    bundle install

You should now be able to run the tests

    bundle exec rake

## Contributors

* [cblunt (Chris Blunt)](https://github.com/cblunt) - Support for passing html options
* [robyurkowski (Rob Yurkowski)](https://github.com/robyurkowski) - Fix deprecation warnings for Rails 3.2
* [tylr (Tyler Love)](https://github.com/tylr) - Bug fix
* [vlado (Vlado Cingel)](https://github.com/vlado) - Properly sanitize filename
* [travisp (Travis Pew)](https://github.com/travisp) - Compatibility for CarrierWave 0.6.0
* [jgorset (Johannes Gorset)](https://github.com/jgorset) - Added note about removing 'store_dir' in README
* [frahugo (Hugo Frappier)](https://github.com/frahugo) - Fix bug where CarrierWaveDirect Validations were being added to non CarrierWaveDirect ActiveRecord models
* [bak (Benjamin Cullen-Kerney)](https://github.com/bak) - Fix bug where CarrierWaveDirect specific methods were being added to non CarrierWaveDirect ActiveRecord models
