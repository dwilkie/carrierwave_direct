# encoding: utf-8
require 'spec_helper'
require 'data/sample_data'

describe CarrierWaveDirect::Uploader do
  include UploaderHelpers
  include ModelHelpers

  let(:subject) { DirectUploader.new }
  let(:mounted_model) { double(sample(:mounted_model_name)) }
  let(:mounted_subject) { DirectUploader.new(mounted_model, sample(:mounted_as)) }
  let(:direct_subject) { DirectUploader.new }


  DirectUploader.fog_credentials.keys.each do |key|
    describe "##{key}" do
      it "should return the #{key.to_s.capitalize}" do
        expect(subject.send(key)).to eq subject.class.fog_credentials[key]
      end

      it "should not be nil" do
        expect(subject.send(key)).to_not be_nil
      end
    end
  end

  it_should_have_accessor(:success_action_redirect)
  it_should_have_accessor(:success_action_status)

  describe "#key=" do
    before { subject.key = sample(:key) }

    it "should set the key" do
      expect(subject.key).to eq sample(:key)
    end

    context "the versions keys" do
      it "should == this subject's key" do
        subject.versions.each do |name, version_subject|
          expect(version_subject.key).to eq subject.key
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
        expect(mounted_subject.key).to match /#{GUID_REGEXP}\/\$\{filename\}$/
      end

      context "and #store_dir returns '#{sample(:store_dir)}'" do
        before do
          allow(mounted_subject).to receive(:store_dir).and_return(sample(:store_dir))
        end

        it "should return '#{sample(:store_dir)}/\#\{guid\}/${filename}'" do
          expect(mounted_subject.key).to match /^#{sample(:store_dir)}\/#{GUID_REGEXP}\/\$\{filename\}$/
        end
      end

      context "and the uploaders url is #default_url" do
        it "should return '*/\#\{guid\}/${filename}'" do
          allow(mounted_subject).to receive(:url).and_return(sample(:s3_file_url))
          allow(mounted_subject).to receive(:present?).and_return(false)
          expect(mounted_subject.key).to match /#{GUID_REGEXP}\/\$\{filename\}$/
        end
      end

      context "but the uploaders url is '#{sample(:s3_file_url)}'" do
        before do
          allow(mounted_subject).to receive(:url).and_return(sample(:s3_file_url))
          allow(mounted_subject).to receive(:present?).and_return(true)
        end

        it "should return '#{sample(:s3_key)}'" do
          expect(mounted_subject.key).to eq sample(:s3_key)
        end

        it "should set the key explicitly in order to update the version keys" do
          expect(mounted_subject).to receive("key=").with(sample(:s3_key))
          mounted_subject.key
        end
      end
    end

    context "where the key is set to '#{sample(:key)}'" do
      before { subject.key = sample(:key) }

      it "should return '#{sample(:key)}'" do
        expect(subject.key).to eq sample(:key)
      end
    end
  end

  describe "#url_scheme_white_list" do
    it "should return nil" do
      expect(subject.url_scheme_white_list).to be_nil
    end
  end

  describe "#key_regexp" do
    it "should return a regexp" do
      expect(subject.key_regexp).to be_a(Regexp)
    end

    context "where #store_dir returns '#{sample(:store_dir)}'" do
      before do
        allow(subject).to receive(:store_dir).and_return(sample(:store_dir))
      end

      context "and #extension_regexp returns '#{sample(:extension_regexp)}'" do
        before do
          allow(subject).to receive(:extension_regexp).and_return(sample(:extension_regexp))
        end

        it "should return /\\A#{sample(:store_dir)}\\/#{GUID_REGEXP}\\/.+\\.#{sample(:extension_regexp)}\\z/" do
          expect(subject.key_regexp).to eq /\A#{sample(:store_dir)}\/#{GUID_REGEXP}\/.+\.(?i)#{sample(:extension_regexp)}(?-i)\z/
        end
      end
    end
  end

  describe "#extension_regexp" do
    shared_examples_for "a globally allowed file extension" do
      it "should return '\\w+'" do
        expect(subject.extension_regexp).to eq "\\w+"
      end
    end

    it "should return a string" do
      expect(subject.extension_regexp).to be_a(String)
    end

    context "where #extension_white_list returns nil" do
      before do
        allow(subject).to receive(:extension_white_list).and_return(nil)
      end

      it_should_behave_like "a globally allowed file extension"
    end

    context "where #extension_white_list returns []" do
      before do
        allow(subject).to receive(:extension_white_list).and_return([])
      end

      it_should_behave_like "a globally allowed file extension"
    end

    context "where #extension_white_list returns ['exe', 'bmp']" do

      before do
        allow(subject).to receive(:extension_white_list).and_return(%w{exe bmp})
      end

      it "should return '(exe|bmp)'" do
        expect(subject.extension_regexp).to eq "(exe|bmp)"
      end
    end
  end

  describe "#has_key?" do
    context "a key has not been set" do

      it "should return false" do
        expect(subject).to_not have_key
      end
    end

    context "the key has been autogenerated" do
      before { subject.key }

      it "should return false" do
        expect(subject).to_not have_key
      end
    end

    context "the key has been set" do
      before { subject.key = sample_key }

      it "should return true" do
        expect(subject).to have_key
      end
    end
  end

  describe "#persisted?" do
    it "should return false" do
      expect(subject).to_not be_persisted
    end
  end

  describe "#filename" do
    context "key is set to '#{sample(:s3_key)}'" do
      before { mounted_subject.key = sample(:s3_key) }

      it "should return '#{sample(:stored_filename)}'" do
        expect(mounted_subject.filename).to eq sample(:stored_filename)
      end
    end

    context "key is set to '#{sample(:key)}'" do
      before { subject.key = sample(:key) }

      it "should return '#{sample(:key)}'" do
        expect(subject.filename).to eq sample(:key)
      end
    end

    context "key is not set" do
      context "but the model's remote #{sample(:mounted_as)} url is: '#{sample(:file_url)}'" do

        before do
          allow(mounted_subject.model).to receive(
            "remote_#{mounted_subject.mounted_as}_url"
          ).and_return(sample(:file_url))
        end

        it "should set the key to contain '#{File.basename(sample(:file_url))}'" do
          mounted_subject.filename
          expect(mounted_subject.key).to match /#{Regexp.escape(File.basename(sample(:file_url)))}$/
        end

        it "should return a filename based off the key and remote url" do
          filename = mounted_subject.filename
          expect(mounted_subject.key).to match /#{Regexp.escape(filename)}$/
        end

        # this ensures that the version subject keys are updated
        # see spec for key= for more details
        it "should set the key explicitly" do
          expect(mounted_subject).to receive(:key=)
          mounted_subject.filename
        end
      end

      context "and the model's remote #{sample(:mounted_as)} url has whitespace in it" do
        before do
          allow(mounted_model).to receive(
            "remote_#{mounted_subject.mounted_as}_url"
          ).and_return("http://anyurl.com/any_path/video_dir/filename 2.avi")
        end

        it "should be sanitized (whitespace replaced with _)" do
          mounted_subject.filename
          expect(mounted_subject.key).to match /filename_2.avi$/
        end
      end

      context "and the model's remote url contains escape characters" do
        before do
            subject.key = nil
            allow(subject).to receive(:present?).and_return(:true)
            allow(subject).to receive(:url).and_return("http://anyurl.com/any_path/video_dir/filename ()+[]2.avi")
        end

        it "should be escaped and replaced with non whitespace characters" do
            expect(subject.key).to match /filename%20%28%29%2B%5B%5D2.avi$/
        end
      end

      context "and the model's remote #{sample(:mounted_as)} url is blank" do
        before do
          allow(mounted_model).to receive(
            "remote_#{mounted_subject.mounted_as}_url"
          ).and_return nil
        end

        it "should return nil" do
          expect(mounted_subject.filename).to be_nil
        end
      end
    end
  end

  describe "#acl" do
    it "should return the correct s3 access policy" do
      expect(subject.acl).to eq (subject.fog_public ? 'public-read' : 'private')
    end
  end

  # http://aws.amazon.com/articles/1434?_encoding=UTF8
  describe "#policy" do
    def decoded_policy(options = {})
      instance = options.delete(:subject) || subject
      JSON.parse(Base64.decode64(instance.policy(options)))
    end

    it "should return Base64-encoded JSON" do
      expect(decoded_policy).to be_a(Hash)
    end

    it "should not contain any new lines" do
      expect(subject.policy).to_not include("\n")
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
          expect(Time.parse(expiration)).to have_expiration
        end
      end

      it "should be encoded as a utc time" do
        expect(Time.parse(expiration)).to be_utc
      end

      it "should be #{sample(:expiration) / 60 } minutes from now when passing {:expiration => #{sample(:expiration)}}" do
        Timecop.freeze(Time.now) do
          expect(Time.parse(expiration(:expiration => sample(:expiration)))).to have_expiration(sample(:expiration))
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
          expect(conditions).to have_condition(:utf8)
        end

        # S3 conditions
        it "'key'" do
          allow(mounted_subject).to receive(:key).and_return(sample(:s3_key))
          expect(conditions(
            :subject => mounted_subject
          )).to have_condition(:key, sample(:s3_key))
        end

        it "'key' without FILENAME_WILDCARD" do
          expect(conditions(
            :subject => mounted_subject
          )).to have_condition(:key, mounted_subject.key.sub("${filename}", ""))
        end

        it "'bucket'" do
          expect(conditions).to have_condition("bucket" => subject.fog_directory)
        end

        it "'acl'" do
          expect(conditions).to have_condition("acl" => subject.acl)
        end

        it "'success_action_redirect'" do
          subject.success_action_redirect = "http://example.com/some_url"
          expect(conditions).to have_condition("success_action_redirect" => "http://example.com/some_url")
        end

        it "'success_action_status'" do
          subject.success_action_status = '200'
          expect(conditions(
            :use_action_status => true
          )).to have_condition('success_action_status' => '200')
        end

        it "does not have 'content-type' when will_include_content_type is false" do
          allow(subject.class).to receive(:will_include_content_type).and_return(false)
          expect(conditions).to_not have_condition('Content-Type')
        end

        it "has 'content-type' when will_include_content_type is true" do
          allow(subject.class).to receive(:will_include_content_type).and_return(true)
          expect(conditions).to have_condition('Content-Type')
        end

        context 'when use_action_status is true' do
          before(:all) do
            DirectUploader.use_action_status = true
          end

          after(:all) do
            DirectUploader.use_action_status = false
          end

          it "'success_action_status'" do
            subject.success_action_status = '200'
            expect(conditions).to have_condition("success_action_status" => "200")
          end

          it "does not have 'success_action_redirect'" do
            subject.success_action_redirect = "http://example.com/some_url"
            expect(conditions).to_not have_condition("success_action_redirect" => "http://example.com/some_url")
          end

          it 'can be overridden by options' do
            subject.success_action_redirect = 'http://example.com/some_url'
            expect(conditions(
              :use_action_status => false
            )).to have_condition('success_action_redirect' => 'http://example.com/some_url')
          end
        end

        context "'content-length-range of'" do
          def have_content_length_range(options = {})
            include([
              "content-length-range",
              options[:min_file_size] || DirectUploader.min_file_size,
              options[:max_file_size] || DirectUploader.max_file_size,
            ])
          end

          it "#{DirectUploader.min_file_size} bytes" do
            expect(conditions).to have_content_length_range
          end

          it "#{DirectUploader.max_file_size} bytes" do
            expect(conditions).to have_content_length_range
          end

          it "#{sample(:min_file_size)} bytes when passing {:min_file_size => #{sample(:min_file_size)}}" do
            expect(conditions(
              :min_file_size => sample(:min_file_size)
            )).to have_content_length_range(:min_file_size => sample(:min_file_size))
          end

          it "#{sample(:max_file_size)} bytes when passing {:max_file_size => #{sample(:max_file_size)}}" do
            expect(conditions(
              :max_file_size => sample(:max_file_size)
            )).to have_content_length_range(:max_file_size => sample(:max_file_size))
          end
        end
      end
    end
  end

  describe "#signature" do
    it "should not contain any new lines" do
      expect(subject.signature).to_not include("\n")
    end

    it "should return a base64 encoded 'sha1' hash of the secret key and policy document" do
      expect(Base64.decode64(subject.signature)).to eq OpenSSL::HMAC.digest(
        OpenSSL::Digest.new('sha1'),
        subject.aws_secret_access_key, subject.policy
      )
    end

    it 'can accept an options hash for computing the policy' do
      opts = { :use_action_status => true }
      expect(Base64.decode64(subject.signature(opts))).to eq OpenSSL::HMAC.digest(
        OpenSSL::Digest.new('sha1'),
        subject.aws_secret_access_key, subject.policy(opts)
      )
    end
  end


  # note that 'video' is hardcoded into the MountedClass support file
  # so changing the sample will cause the tests to fail
  context "a class has a '#{sample(:mounted_as)}' mounted" do
    describe "#{sample(:mounted_as).to_s.capitalize}Uploader" do
      describe "##{sample(:mounted_as)}" do
        it "should be defined" do
          expect(direct_subject).to be_respond_to(sample(:mounted_as))
        end

        it "should return itself" do
          expect(direct_subject.send(sample(:mounted_as))).to eq direct_subject
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
              expect(store_path).to match /#{sample(:stored_version_filename)}$/
            end

            it "should not be like '#{sample(:version)}_#{sample(:stored_filename_base)}'" do
              expect(store_path).to_not match /#{sample(:version)}_#{sample(:stored_filename_base)}/
            end
          end
        end
      end
    end
  end
end
