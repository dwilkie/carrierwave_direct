require 'spec_helper'

describe CarrierWaveDirect::Test::Helpers do
  include CarrierWaveDirect::Test::Helpers

  describe "#sample_key" do
    context "passing DirectUploader" do
      context "where DirectUploader's extension white list is" do
        context "['exe']" do
          before do
            DirectUploader.stub(:extension_white_list).and_return(%w{exe})
          end
          it "should return 'uploads/guid/filename.exe'" do
            sample_key(DirectUploader).should =~ /^uploads\/[a-f\d\-]+\/filename\.exe$/
          end
        end
        context "[]" do
          before do
            DirectUploader.stub(:extension_white_list).and_return([])
          end
          it "should return 'uploads/guid/filename.extension'" do
            sample_key(DirectUploader).should =~ /^uploads\/[a-f\d\-]+\/filename\.extension$/
          end
        end
      end
      context "with options" do
        shared_examples_for "an invalid key" do
          it "should return 'uploads/filename.extension'" do
            sample_key(DirectUploader, options).should =~ /^uploads\/filename\.extension$/
          end
        end

        shared_examples_for "a custom filename" do
          it "should return 'uploads/guid/some_file.reg'" do
            sample_key(DirectUploader, options).should =~ /^uploads\/[a-f\d\-]+\/some_file\.reg$/
          end
        end

        context ":invalid => true" do
          it_should_behave_like "an invalid key" do
            let(:options) { { :invalid => true } }
          end
        end
        context ":valid => false" do
          it_should_behave_like "an invalid key" do
            let(:options) { { :valid => false } }
          end
        end
        context ":base => 'upload_dir/porno/movie/${filename}'" do
          it "should return 'upload_dir/porno/movie/guid/filename.extension'" do
            sample_key(
              DirectUploader,
              :base => "upload_dir/porno/movie/${filename}"
            ).should == "upload_dir/porno/movie/filename.extension"
          end
        end
        context ":filename => 'some_file.reg'" do
          it_should_behave_like "a custom filename" do
            let(:options) { { :filename => "some_file.reg" } }
          end
        end
        context ":filename => 'some_file', :extension => 'reg'" do
          it_should_behave_like "a custom filename" do
            let(:options) { { :filename => "some_file", :extension => "reg" } }
          end
        end

        context ":model_class => 'SoftPorn', :mounted_as => :movie" do
          it "should return 'uploads/soft_porn/movie/guid/filename.extension'" do
            sample_key(
              DirectUploader,
              :model_class => "SoftPorn",
              :mounted_as => "movie"
            ).should =~ /^uploads\/soft_porn\/movie\/[a-f\d\-]+\/filename\.extension$/
          end
        end
      end
    end
  end
end

