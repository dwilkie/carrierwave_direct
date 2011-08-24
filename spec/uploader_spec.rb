require 'spec_helper'

describe CarrierWaveDirect::Uploader do
  include UploaderHelpers
  include ModelHelpers

  SAMPLE_DATA = {
    :path => "upload_dir/bliind.exe",
    :key => "some key",
    :guid => "guid",
    :store_dir => "store_dir",
    :url => "http://example.com/some_url",
    :expiration => 60,
    :max_file_size => 10485760,
    :file_url => "http://anyurl.com/any_path/video_dir/filename.jpg",
    :mounted_model_name => "Porno",
    :mounted_as => :video,
    :filename => "filename",
    :extension => ".avi",
    :version => :thumb
  }

  SAMPLE_DATA.merge!(
    :stored_filename_base => "#{sample(:guid)}/#{sample(:filename)}"
  )

  SAMPLE_DATA.merge!(
    :stored_filename => "#{sample(:stored_filename_base)}#{sample(:extension)}",
    :stored_version_filename => "#{sample(:stored_filename_base)}_#{sample(:version)}#{sample(:extension)}"
  )

  SAMPLE_DATA.merge!(
    :s3_key => "#{sample(:store_dir)}/#{sample(:stored_filename)}"
  )

  SAMPLE_DATA.freeze

  let(:uploader) { DirectUploader.new }
  let(:mounted_model) { mock(sample(:mounted_model_name)) }
  let(:mounted_uploader) { DirectUploader.new(mounted_model, sample(:mounted_as)) }
  let(:direct_uploader) { DirectUploader.new }

  describe ".store_dir" do
    context "passing no args" do
      it "should return 'uploads'" do
        uploader.class.store_dir.should == "uploads"
      end
    end
    context ":model_class => 'NightOut', :mounted_as => :pic" do
      it "should return 'uploads/night_out/pic'" do
        uploader.class.store_dir(:model_class => "NightOut", :mounted_as => :pic).should == "uploads/night_out/pic"
      end
    end
  end

  describe ".extension_white_list" do
    it "should return an empty array" do
      uploader.class.extension_white_list.should == []
    end
  end

  describe ".allowed_file_types" do
    context "with no extension whitelist" do
      before do
        uploader.class.stub(:extension_white_list).and_return([])
      end

      context "passing no args" do
        it "should return and empty array" do
          uploader.class.allowed_file_types.should == []
        end
      end

      context ":as => :regexp_string" do
        it "should return '\\.\\w+'" do
          uploader.class.allowed_file_types(:as => :regexp_string).should == "\\.\\w+"
        end
      end
    end

    context "where the extension whitelist is ['jpg', 'jpeg', 'gif', 'png']" do
      before do
        uploader.class.stub(:extension_white_list).and_return(%w(jpg jpeg gif png))
      end

      context "passing no args" do
        it "should return ['jpg', 'jpeg', 'gif', 'png']" do
          uploader.class.allowed_file_types.should == %w(jpg jpeg gif png)
        end
      end

      context ":as => :regexp_string" do
        it "should return '\\.(jpg|jpeg|gif|png)'" do
          uploader.class.allowed_file_types(:as => :regexp_string).should == "\\.(jpg|jpeg|gif|png)"
        end
      end
    end
  end

  describe ".key" do
    context ":store_dir => 'uploads/night_out/pic'" do
      let(:options) { {:store_dir => 'uploads/night_out/pic' } }

      it "should == uploads/night_out/pic/{guid}/${filename}'" do
        uploader.class.key(
          options
        ).should =~ /^uploads\/night_out\/pic\/[\d\a-f\-]+\/\$\{filename\}$/
      end
    end

    context ":filename => 'some_file.jpg'" do
      let(:options) { {:filename => 'some_file.jpg' } }

      it "should end with 'some_file.jpg'" do
        uploader.class.key(
          options
        ).should =~ /some_file\.jpg$/
      end
    end

    context ":model_class =>'NightOut', :mounted_as => :pic" do
      let(:options) { {:model_class =>'NightOut', :mounted_as => :pic} }

      before { uploader.class.stub(:store_dir).and_return("store_dir") }

      it 'should == #{store_dir(NightOut, :pic)}/{guid}/${filename}' do
        uploader.class.key(
          options
        ).should =~ /^store_dir\/[\d\a-f\-]+\/\$\{filename\}$/
      end

      context ":as => :regexp" do

        before {options.merge!(:as => :regexp)}

        it "should return a regexp" do
          uploader.class.key(options).should be_a(Regexp)
        end

        context "a valid key" do
          let(:key) {
            sample_key(:uploader => "NightOut", :mounted_as => :pic, :extension => "jpg")
          }

          def sample_extension_regexp(ext)
            "\\.(#{ext})"
          end

          context "with a valid extension" do
            before do
              uploader.class.stub(:allowed_file_types).with(
                :as => :regexp_string
              ).and_return(sample_extension_regexp("jpg"))
            end

            it "should be matched by the returned regexp" do
              key.should =~ uploader.class.key(options)
            end
          end

          context "with an invalid extension" do
            before do
              uploader.class.stub(:allowed_file_types).with(
                :as => :regexp_string
              ).and_return(sample_extension_regexp("exe"))
            end

            it "should not be matched by the returned regexp" do
              key.should_not =~ uploader.class.key(options)
            end
          end
        end

        context "an invalid key" do
          let(:key) {
            sample_key(:invalid => true, :uploader => "NightOut", :mounted_as => :pic)
          }

          it "should not be matched by the returned regexp" do
            key.should_not =~ uploader.class.key(options)
          end
        end
      end
    end
  end

  describe ".upload_expiration" do
    it "should be 10 hours" do
      uploader.class.upload_expiration.should == 36000
    end
  end

  describe ".max_file_size" do
    it "should be 5 MB" do
      uploader.class.max_file_size.should == 5242880
    end
  end

  DirectUploader.fog_credentials.keys.each do |key|
    describe "##{key}" do
      it "should return the #{key.to_s.capitalize}" do
        uploader.send(key).should == DirectUploader.fog_credentials[key]
      end

      it "should not be nil" do
        uploader.send(key).should_not be_nil
      end
    end
  end

  it_should_have_accessor(:success_action_redirect, :it => DirectUploader.new)

  describe "#extension_white_list" do
    it "should return the result from .allowed_file_types" do
      uploader.class.stub(:allowed_file_types).and_return("allowed file types")
      uploader.extension_white_list.should == "allowed file types"
    end
  end

  describe "#key=" do
    before { uploader.key = sample(:key) }

    it "should set the key" do
      uploader.key.should == sample(:key)
    end

    context "the versions keys" do
      it "should == this uploader's key" do
        uploader.versions.each do |name, version_uploader|
          version_uploader.key.should == uploader.key
        end
      end
    end
  end

  describe "#key" do
    context "where the key is not set" do
      before do
        mounted_uploader.key = nil
        mounted_uploader.stub(:store_dir).and_return("store_dir")
      end

      it "should return the result of .key :store_dir => store_dir" do
        mounted_uploader.class.stub(:key).with(:store_dir => "store_dir").and_return(sample(:key))
        mounted_uploader.key.should == sample(:key)
      end
    end

    context "where the key is set to '#{sample(:key)}'" do
      before { uploader.key = sample(:key) }

      it "should return '#{sample(:key)}'" do
        uploader.key.should == sample(:key)
      end
    end
  end

  describe "#has_key?" do
    context "a key has not been set" do

      it "should return false" do
        uploader.should_not have_key
      end
    end

    context "the key has been autogenerated" do
      before { uploader.key }

      it "should return false" do
        uploader.should_not have_key
      end
    end

    context "the key has been set" do
      before { uploader.key = sample_key(:mounted_as => :pic, :uploader => "NightOut") }

      it "should return true" do
        uploader.should have_key
      end
    end
  end

  describe "#direct_fog_url" do
    it "should return the result from CarrierWave::Storage::Fog::File#public_url" do
      uploader.direct_fog_url.should == CarrierWave::Storage::Fog::File.new(
        uploader, nil, nil
      ).public_url
    end

    context ":with_path => true" do
      context "#key is set to '#{sample(:path)}'" do
        before { uploader.key = sample(:path) }

        it "should return the full url with '/#{sample(:path)}' as the path" do
          URI.parse(uploader.direct_fog_url(:with_path => true)).path.should == "/#{sample(:path)}"
        end
      end
    end
  end

  describe "#persisted?" do
    it "should return false" do
      uploader.should_not be_persisted
    end
  end

  describe "#filename" do
    context "key is set to '#{sample(:s3_key)}'" do
      before { mounted_uploader.key = sample(:s3_key) }

      it "should return '#{sample(:stored_filename)}'" do
        mounted_uploader.filename.should == sample(:stored_filename)
      end
    end

    context "key is set to '#{sample(:key)}'" do
      before { uploader.key = sample(:key) }

      it "should return '#{sample(:key)}'" do
        uploader.filename.should == sample(:key)
      end
    end

    context "key is not set" do
      context "but the model's remote #{sample(:mounted_as)} url is: '#{sample(:file_url)}'" do

        before do
          mounted_uploader.model.stub(
            "remote_#{mounted_uploader.mounted_as}_url"
          ).and_return(sample(:file_url))
        end

        it "should set the key to contain '#{File.basename(sample(:file_url))}'" do
          mounted_uploader.filename
          mounted_uploader.key.should =~ /#{Regexp.escape(File.basename(sample(:file_url)))}$/
        end

        it "should return a filename based off the key and remote url" do
          filename = mounted_uploader.filename
          mounted_uploader.key.should =~ /#{Regexp.escape(filename)}$/
        end

        # this ensures that the version uploader keys are updated
        # see spec for key= for more details
        it "should set the key explicitly" do
          mounted_uploader.should_receive(:key=)
          mounted_uploader.filename
        end
      end

      context "and the model's remote #{sample(:mounted_as)} url is blank" do
        before do
          mounted_model.stub(
            "remote_#{mounted_uploader.mounted_as}_url"
          ).and_return nil
        end

        it "should return nil" do
          mounted_uploader.filename.should be_nil
        end
      end
    end
  end

  describe "#store_dir" do
    context "for a '#{sample(:mounted_model_name)}' mounted as a '#{sample(:mounted_as)}'" do

      it "should return the result from .store_dir :model_class => #{sample(:mounted_model_name)}, :mounted_as => :#{sample(:mounted_as)}" do
        uploader.class.stub(:store_dir).with(
          :model_class => mounted_model.class,
          :mounted_as => mounted_uploader.mounted_as
        ).and_return("store_dir")
        mounted_uploader.store_dir.should == "store_dir"
      end
    end
  end

  describe "#acl" do
    it "should return the sanitized s3 access policy" do
      uploader.acl.should == uploader.s3_access_policy.to_s.gsub("_", "-")
    end
  end

  # http://aws.amazon.com/articles/1434?_encoding=UTF8
  describe "#policy" do
    def decoded_policy(options = {})
      instance = options.delete(:uploader) || uploader
      JSON.parse(Base64.decode64(instance.policy(options)))
    end

    it "should return Base64-encoded JSON" do
      decoded_policy.should be_a(Hash)
    end

    it "should not contain any new lines" do
      uploader.policy.should_not include("\n")
    end

    context "expiration" do
      def expiration(options = {})
        decoded_policy(options)["expiration"]
      end

      # Stolen from rails
      def string_to_time(str)
        d = ::Date._parse(str, false).values_at(
          :year, :mon, :mday, :hour, :min, :sec, :sec_fraction, :offset
        ).map { |arg| arg || 0 }
        d[6] *= 1000000
        Time.utc(*d[0..6]) - d[7]
      end


      def have_expiration(expires_in = DirectUploader.upload_expiration)
        eql(
          string_to_time(
            JSON.parse({
              "expiry" => Time.now + expires_in
            }.to_json)["expiry"]
          )
        )
      end

      it "should be #{DirectUploader.upload_expiration / 3600} hours from now" do
        Timecop.freeze(Time.now) do
          string_to_time(expiration).should have_expiration
        end
      end

      it "should be #{sample(:expiration) / 60 } minutes from now when passing {:expiration => #{sample(:expiration)}}" do
        Timecop.freeze(Time.now) do
          string_to_time(expiration(:expiration => sample(:expiration))).should have_expiration(sample(:expiration))
        end
      end
    end

    context "conditions" do
      def conditions(options = {})
        decoded_policy(options)["conditions"]
      end

      def have_condition(field, value = nil)
        field.is_a?(Hash) ? include(field) : include(["starts-with", "$#{field}", value.to_s])
      end

      context "should include" do
        # Rails form builder conditions
        it "'utf8'" do
          conditions.should have_condition(:utf8)
        end

        # S3 conditions
        it "'key'" do
          mounted_uploader.stub(:store_dir).and_return(sample(:s3_key))
          mounted_uploader.key
          conditions(
            :uploader => mounted_uploader
          ).should have_condition(:key, sample(:s3_key))
        end

        it "'bucket'" do
          conditions.should have_condition("bucket" => uploader.fog_directory)
        end

        it "'acl'" do
          conditions.should have_condition("acl" => uploader.acl)
        end

        it "'success_action_redirect'" do
          uploader.success_action_redirect = "http://example.com/some_url"
          conditions.should have_condition("success_action_redirect" => "http://example.com/some_url")
        end

        context "'content-length-range of'" do

          def have_content_length_range(max_file_size = DirectUploader.max_file_size)
            include(["content-length-range", 1, max_file_size])
          end

          it "#{DirectUploader.max_file_size} bytes" do
            conditions.should have_content_length_range
          end

          it "#{sample(:max_file_size)} bytes when passing {:max_file_size => #{sample(:max_file_size)}}" do
            conditions(
              :max_file_size => sample(:max_file_size)
            ).should have_content_length_range(sample(:max_file_size))
          end
        end
      end
    end
  end

  describe "#signature" do
    it "should not contain any new lines" do
      uploader.signature.should_not include("\n")
    end

    it "should return a base64 encoded 'sha1' hash of the secret key and policy document" do
      Base64.decode64(uploader.signature).should == OpenSSL::HMAC.digest(
        OpenSSL::Digest::Digest.new('sha1'),
        uploader.aws_secret_access_key, uploader.policy
      )
    end
  end

  # note that 'video' is hardcoded into the MountedClass support file
  # so changing the sample will cause the tests to fail
  context "a class has a '#{sample(:mounted_as)}' mounted" do
    describe "#{sample(:mounted_as).capitalize}Uploader" do
      describe "##{sample(:mounted_as)}" do
        it "should be defined" do
          direct_uploader.should be_respond_to(sample(:mounted_as))
        end

        it "should return itself" do
          direct_uploader.send(sample(:mounted_as)).should == direct_uploader
        end
      end

      context "has a '#{sample(:version)}' version" do
        let(:video_uploader) { MountedClass.new.video }

        before do
          DirectUploader.version(sample(:version))
        end

        context "and the key is '#{sample(:s3_key)}'" do
          before do
            video_uploader.key = sample(:s3_key)
          end

          context "the store path" do
            let(:store_path) { video_uploader.send(sample(:version)).store_path }

            it "should be like '#{sample(:stored_version_filename)}'" do
              store_path.should =~ /#{sample(:stored_version_filename)}$/
            end

            it "should not be like '#{sample(:version)}_#{sample(:stored_filename_base)}'" do
              store_path.should_not =~ /#{sample(:version)}_#{sample(:stored_filename_base)}/
            end
          end
        end
      end
    end
  end
end

