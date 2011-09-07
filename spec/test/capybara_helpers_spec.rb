# encoding: utf-8

require 'spec_helper'

describe CarrierWaveDirect::Test::CapybaraHelpers do
  class ExampleSpec
    include CarrierWaveDirect::Test::CapybaraHelpers
  end

  let(:subject) { ExampleSpec.new }
  let(:page) { mock("Page").as_null_object }
  let(:selector) { mock("Selector") }

  def stub_page
    subject.stub(:page).and_return(page)
  end

  def find_element_value(css, value)
    page.stub(:find).with(css).and_return(selector)
    selector.stub(:value).and_return(value)
  end

  describe "#attach_file_for_direct_upload" do
    context "'path/to/file.ext'" do
      it "should attach a file with the locator => 'file'" do
        subject.should_receive(:attach_file).with("file", "path/to/file.ext")
        subject.attach_file_for_direct_upload "path/to/file.ext"
      end
    end
  end

  describe "#upload_directly" do
    let(:uploader) { DirectUploader.new }

    def upload_directly(options = {})
      options[:button_locator] ||= ""
      button_locator = options.delete(:button_locator)
      subject.upload_directly(uploader, button_locator, options)
    end

    def stub_common
      stub_page
      find_element_value("input[@name='success_action_redirect']", "http://example.com")
      subject.stub(:visit)
    end

    before do
      subject.stub(:click_button)
    end

    shared_examples_for "submitting the form" do
      let(:options) { {} }

      it "should submit the form" do
        subject.should_receive(:click_button).with("Upload!")
        upload_directly(options.merge(:button_locator => "Upload!"))
      end
    end

    shared_examples_for ":success => false" do
      let(:options) { { :success => false } }

      it "should not redirect" do
        subject.should_not_receive(:visit)
        upload_directly(options)
      end
    end

    context "passing no options" do
      before do
        stub_common
        subject.stub(:find_key).and_return("upload_dir/guid/$filename")
        subject.stub(:find_upload_path).and_return("path/to/file.ext")
      end

      it_should_behave_like "submitting the form"

      it "should redirect to the page's success_action_redirect url" do
        subject.should_receive(:visit).with(/^http:\/\/example.com/)
        upload_directly
      end

      context "the redirect url's params" do
        it "should include the bucket name" do
          subject.should_receive(:visit).with(/bucket=/)
          upload_directly
        end

        it "should include an etag" do
          subject.should_receive(:visit).with(/etag=/)
          upload_directly
        end

        it "should include the key derived from the form" do
          subject.should_receive(:visit).with(/key=upload_dir%2Fguid%2Ffile.ext/)
          upload_directly
        end
      end
    end

    context "with options" do
      context ":redirect_key => 'some redirect key'" do
        before do
          stub_common
        end

        context "the redirect url's params" do
          it "should include the key from the :redirect_key option" do
            subject.should_receive(:visit).with(/key=some\+redirect\+key/)
            upload_directly(:redirect_key => "some redirect key")
          end
        end
      end

      context ":success => false" do
        let(:options) { { :success => false } }

        it_should_behave_like "submitting the form" do
          let(:options) { { :success => false } }
        end

        it_should_behave_like ":success => false"
      end

      context ":fail => true" do
        it_should_behave_like "submitting the form" do
          let(:options) { { :fail => true } }
        end

        it_should_behave_like ":success => false" do
          let(:options) { { :fail => true } }
        end
      end
    end
  end

  describe "#find_key" do
    before do
      stub_page
      find_element_value("input[@name='key']", "key")
    end

    it "should try to find the key on the page" do
      subject.find_key.should == "key"
    end
  end

  describe "#find_upload_path" do
    before do
      stub_page
      find_element_value("input[@name='file']", "upload path")
    end

    it "should try to find the upload path on the page" do
      subject.find_upload_path.should == "upload path"
    end
  end

end

