# encoding: utf-8

require 'spec_helper'

describe CarrierWaveDirect::Uploader do
  include UploaderHelpers
  include ModelHelpers

  SAMPLE_DATA = {
    :path => "upload_dir/bliind.exe",
    :path_with_special_chars => "upload_dir/some file & blah.exe",
    :key => "some key",
    :guid => "guid",
    :store_dir => "store_dir",
    :extension_regexp => "(avi)",
    :url => "http://example.com/some_url",
    :expiration => 60,
    :max_file_size => 10485760,
    :file_url => "http://anyurl.com/any_path/video_dir/filename.avi",
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

  let(:subject) { DirectUploader.new }
  let(:mounted_model) { mock(sample(:mounted_model_name)) }
  let(:mounted_subject) { DirectUploader.new(mounted_model, sample(:mounted_as)) }
  let(:direct_subject) { DirectUploader.new }

  describe ".upload_expiration" do
    it "should be 10 hours" do
      subject.class.upload_expiration.should == 36000
    end
  end

  describe ".max_file_size" do
    it "should be 5 MB" do
      subject.class.max_file_size.should == 5242880
    end
  end

  DirectUploader.fog_credentials.keys.each do |key|
    describe "##{key}" do
      it "should return the #{key.to_s.capitalize}" do
        subject.send(key).should == DirectUploader.fog_credentials[key]
      end

      it "should not be nil" do
        subject.send(key).should_not be_nil
      end
    end
  end

  it_should_have_accessor(:success_action_redirect)

  describe "#key=" do
    before { subject.key = sample(:key) }

    it "should set the key" do
      subject.key.should == sample(:key)
    end

    context "the versions keys" do
      it "should == this subject's key" do
        subject.versions.each do |name, version_subject|
          version_subject.key.should == subject.key
        end
      end
    end
  end

  describe "#key" do
    context "where the key is not set" do
      before do
        mounted_subject.key = nil
      end

      it "should return '*/\#\{guid\}/${filename}'" do
        mounted_subject.key.should =~ /#{GUID_REGEXP}\/\$\{filename\}$/
      end

      context "and #store_dir returns '#{sample(:store_dir)}'" do
        before do
          mounted_subject.stub(:store_dir).and_return(sample(:store_dir))
        end

        it "should return '#{sample(:store_dir)}/\#\{guid\}/${filename}'" do
          mounted_subject.key.should =~ /^#{sample(:store_dir)}\/#{GUID_REGEXP}\/\$\{filename\}$/
        end
      end
    end

    context "where the key is set to '#{sample(:key)}'" do
      before { subject.key = sample(:key) }

      it "should return '#{sample(:key)}'" do
        subject.key.should == sample(:key)
      end
    end
  end

  describe "#url_scheme_white_list" do
    it "should return nil" do
      subject.url_scheme_white_list.should be_nil
    end
  end

  describe "#key_regexp" do
    it "should return a regexp" do
      subject.key_regexp.should be_a(Regexp)
    end

    context "where #store_dir returns '#{sample(:store_dir)}'" do
      before do
        subject.stub(:store_dir).and_return(sample(:store_dir))
      end

      context "and #extension_regexp returns '#{sample(:extension_regexp)}'" do
        before do
          subject.stub(:extension_regexp).and_return(sample(:extension_regexp))
        end

        it "should return /\\A#{sample(:store_dir)}\\/#{GUID_REGEXP}\\/.+\\.#{sample(:extension_regexp)}\\z/" do
          subject.key_regexp.should ==  /\A#{sample(:store_dir)}\/#{GUID_REGEXP}\/.+\.#{sample(:extension_regexp)}\z/
        end
      end
    end
  end

  describe "#extension_regexp" do
    shared_examples_for "a globally allowed file extension" do
      it "should return '\\w+'" do
        subject.extension_regexp.should == "\\w+"
      end
    end

    it "should return a string" do
      subject.extension_regexp.should be_a(String)
    end

    context "where #extension_white_list returns nil" do
      before do
        subject.stub(:extension_white_list).and_return(nil)
      end

      it_should_behave_like "a globally allowed file extension"
    end

    context "where #extension_white_list returns []" do
      before do
        subject.stub(:extension_white_list).and_return([])
      end

      it_should_behave_like "a globally allowed file extension"
    end

    context "where #extension_white_list returns ['exe', 'bmp']" do

      before do
        subject.stub(:extension_white_list).and_return(%w{exe bmp})
      end

      it "should return '(exe|bmp)'" do
        subject.extension_regexp.should == "(exe|bmp)"
      end
    end
  end

  describe "#has_key?" do
    context "a key has not been set" do

      it "should return false" do
        subject.should_not have_key
      end
    end

    context "the key has been autogenerated" do
      before { subject.key }

      it "should return false" do
        subject.should_not have_key
      end
    end

    context "the key has been set" do
      before { subject.key = sample_key }

      it "should return true" do
        subject.should have_key
      end
    end
  end

  describe "#direct_fog_url" do
    it "should return the result from CarrierWave::Storage::Fog::File#public_url" do
      subject.direct_fog_url.should == CarrierWave::Storage::Fog::File.new(
        subject, nil, nil
      ).public_url
    end

    context ":with_path => true" do

      context "#key is set to '#{sample(:path_with_special_chars)}'" do
        before { subject.key = sample(:path_with_special_chars) }

        it "should return the full url with '/#{URI.escape(sample(:path_with_special_chars))}' as the path" do
          URI.parse(subject.direct_fog_url(:with_path => true)).path.should == "/#{URI.escape(sample(:path_with_special_chars))}"
        end
      end

      context "#key is set to '#{sample(:path)}'" do
        before { subject.key = sample(:path) }

        it "should return the full url with '/#{sample(:path)}' as the path" do
          URI.parse(subject.direct_fog_url(:with_path => true)).path.should == "/#{sample(:path)}"
        end
      end
    end
  end

  describe "#persisted?" do
    it "should return false" do
      subject.should_not be_persisted
    end
  end

  describe "#filename" do
    context "key is set to '#{sample(:s3_key)}'" do
      before { mounted_subject.key = sample(:s3_key) }

      it "should return '#{sample(:stored_filename)}'" do
        mounted_subject.filename.should == sample(:stored_filename)
      end
    end

    context "key is set to '#{sample(:key)}'" do
      before { subject.key = sample(:key) }

      it "should return '#{sample(:key)}'" do
        subject.filename.should == sample(:key)
      end
    end

    context "key is not set" do
      context "but the model's remote #{sample(:mounted_as)} url is: '#{sample(:file_url)}'" do

        before do
          mounted_subject.model.stub(
            "remote_#{mounted_subject.mounted_as}_url"
          ).and_return(sample(:file_url))
        end

        it "should set the key to contain '#{File.basename(sample(:file_url))}'" do
          mounted_subject.filename
          mounted_subject.key.should =~ /#{Regexp.escape(File.basename(sample(:file_url)))}$/
        end

        it "should return a filename based off the key and remote url" do
          filename = mounted_subject.filename
          mounted_subject.key.should =~ /#{Regexp.escape(filename)}$/
        end

        # this ensures that the version subject keys are updated
        # see spec for key= for more details
        it "should set the key explicitly" do
          mounted_subject.should_receive(:key=)
          mounted_subject.filename
        end
      end
      
      context "and the model's remote #{sample(:mounted_as)} url has whitespace in it" do
        before do
          mounted_model.stub(
            "remote_#{mounted_subject.mounted_as}_url"
          ).and_return("http://anyurl.com/any_path/video_dir/filename 2.avi")
        end
        
        it "should be sanitized (whitespace replaced with _)" do
          mounted_subject.filename
          mounted_subject.key.should =~ /filename_2.avi$/
        end
      end
      
      context "and the model's remote #{sample(:mounted_as)} url is blank" do
        before do
          mounted_model.stub(
            "remote_#{mounted_subject.mounted_as}_url"
          ).and_return nil
        end

        it "should return nil" do
          mounted_subject.filename.should be_nil
        end
      end
    end
  end

  describe "#acl" do
    it "should return the correct s3 access policy" do
      subject.acl.should == (subject.fog_public ? 'public-read' : 'private')
    end
  end

  # http://aws.amazon.com/articles/1434?_encoding=UTF8
  describe "#policy" do
    def decoded_policy(options = {})
      instance = options.delete(:subject) || subject
      JSON.parse(Base64.decode64(instance.policy(options)))
    end

    it "should return Base64-encoded JSON" do
      decoded_policy.should be_a(Hash)
    end

    it "should not contain any new lines" do
      subject.policy.should_not include("\n")
    end

    context "expiration" do
      def expiration(options = {})
        decoded_policy(options)["expiration"]
      end

      def have_expiration(expires_in = DirectUploader.upload_expiration)
        eql(
          Time.parse(
            JSON.parse({
              "expiry" => Time.now + expires_in
            }.to_json)["expiry"]
          )
        )
      end

      it "should be #{DirectUploader.upload_expiration / 3600} hours from now" do
        Timecop.freeze(Time.now) do
          Time.parse(expiration).should have_expiration
        end
      end

      it "should be encoded as a utc time" do
        Time.parse(expiration).should be_utc
      end

      it "should be #{sample(:expiration) / 60 } minutes from now when passing {:expiration => #{sample(:expiration)}}" do
        Timecop.freeze(Time.now) do
          Time.parse(expiration(:expiration => sample(:expiration))).should have_expiration(sample(:expiration))
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
          mounted_subject.stub(:store_dir).and_return(sample(:s3_key))
          mounted_subject.key
          conditions(
            :subject => mounted_subject
          ).should have_condition(:key, sample(:s3_key))
        end

        it "'bucket'" do
          conditions.should have_condition("bucket" => subject.fog_directory)
        end

        it "'acl'" do
          conditions.should have_condition("acl" => subject.acl)
        end

        it "'success_action_redirect'" do
          subject.success_action_redirect = "http://example.com/some_url"
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
      subject.signature.should_not include("\n")
    end

    it "should return a base64 encoded 'sha1' hash of the secret key and policy document" do
      Base64.decode64(subject.signature).should == OpenSSL::HMAC.digest(
        OpenSSL::Digest::Digest.new('sha1'),
        subject.aws_secret_access_key, subject.policy
      )
    end
  end

  # note that 'video' is hardcoded into the MountedClass support file
  # so changing the sample will cause the tests to fail
  context "a class has a '#{sample(:mounted_as)}' mounted" do
    describe "#{sample(:mounted_as).to_s.capitalize}Uploader" do
      describe "##{sample(:mounted_as)}" do
        it "should be defined" do
          direct_subject.should be_respond_to(sample(:mounted_as))
        end

        it "should return itself" do
          direct_subject.send(sample(:mounted_as)).should == direct_subject
        end
      end

      context "has a '#{sample(:version)}' version" do
        let(:video_subject) { MountedClass.new.video }

        before do
          DirectUploader.version(sample(:version))
        end

        context "and the key is '#{sample(:s3_key)}'" do
          before do
            video_subject.key = sample(:s3_key)
          end

          context "the store path" do
            let(:store_path) { video_subject.send(sample(:version)).store_path }

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
