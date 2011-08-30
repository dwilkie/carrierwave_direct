require 'spec_helper'
require 'carrierwave/orm/activerecord'
require 'carrierwave_direct/orm/activerecord'

describe CarrierWaveDirect::ActiveRecord do
  dbconfig = {
    :adapter => 'sqlite3',
    :database => ':memory:'
  }

  class TestMigration < ActiveRecord::Migration
    def self.up
      create_table :parties, :force => true do |t|
        t.column :video, :string
      end
    end

    def self.down
      drop_table :parties
    end
  end

  class Party < ActiveRecord::Base
    mount_uploader :video, DirectUploader
  end

  ActiveRecord::Base.establish_connection(dbconfig)

  # turn off migration output
  ActiveRecord::Migration.verbose = false

  before(:all) { TestMigration.up }
  after(:all) { TestMigration.down }
  after { Party.delete_all }

  describe "class Party < ActiveRecord::Base; mount_uploader :video, DirectUploader; end" do
    $arclass = 0
    include UploaderHelpers

    let(:party_class) { Class.new(Party) }
    let(:subject) { party_class.new }

    before do
      # see https://github.com/jnicklas/carrierwave/blob/master/spec/orm/activerecord_spec.rb
      $arclass += 1
      Object.const_set("Party#{$arclass}", party_class)
      party_class.table_name = "parties"
    end

    shared_examples_for "validating uniqueness of filenames" do
      context "a Party with a mounted video exists" do
        before do
          subject.video.key = "bliind"
          subject.save
        end

        context "another Party with a duplicate video filename" do
          let(:another_party) do
            another_party = party_class.new
            another_party.video.key = subject.video.key
            another_party
          end

          it "should not be valid" do
            another_party.should_not be_valid
          end

          it "should use I18n for the error messages" do
            another_party.valid?
            another_party.errors[:video].should == [I18n.t("errors.messages.carrierwave_direct_filename_taken")]
          end
        end
      end
    end

    shared_examples_for "validating format of filenames" do
      context "the video's key does not contain a guid" do

        before do
          subject.video.key = sample_key(:valid => false)
        end

        it "should not be valid on create" do
          subject.should_not be_valid
        end

        it "should be valid on update" do
          subject.save(:validate => false)
          subject.should be_valid
        end

        it "should use I18n for the error messages" do
          subject.valid?
          subject.errors[:video].should == [I18n.t("errors.messages.carrierwave_direct_filename_invalid")]
        end

        context "the uploader has an extension white list" do
          before do
            subject.video.stub(:extension_white_list).and_return(%w{exe bmp})
          end

          it "should include the white listed extensions in the error message" do
            subject.valid?
            subject.errors[:video].first.should include("exe and bmp")
          end
        end
      end
    end

    shared_examples_for "a remote net url i18n error message" do
      it "should use i18n for the error messages" do
        subject.valid?
        subject.errors[:video].should == [I18n.t("errors.messages.carrierwave_direct_remote_net_url_invalid", i18n_options)]
      end
    end

    shared_examples_for "validating format of remote net urls" do
      context "with an invalid remote image net url" do

        context "on create" do
          context "where the uploader has an extension white list" do
            before do
              subject.video.stub(:extension_white_list).and_return(%w{avi mp4})
            end

            context "and the url's extension is included in the list" do
              before do
                subject.remote_video_net_url = "http://example.com/some_video.mp4"
              end

              it "should be valid" do
                subject.should be_valid
              end
            end

            context "but the url's extension is not included in the list" do
              before do
                subject.remote_video_net_url = "http://example.com/some_video.mp3"
              end

              it "should not be valid" do
                subject.should_not be_valid
              end

              it_should_behave_like "a remote net url i18n error message" do
                let(:i18n_options) { {:extension_white_list => %w{avi mp4} } }
              end

              it "should include the white listed extensions in the error message" do
                subject.valid?
                subject.errors[:video].first.should include("avi and mp4")
              end
            end
          end

          context "where the url is invalid" do
            before do
              subject.remote_video_net_url = "http$://example.com/some_video.mp4"
            end

            it "should not be valid" do
              subject.should_not be_valid
            end

            it_should_behave_like "a remote net url i18n error message" do
              let(:i18n_options) { nil }
            end
          end

          context "where the uploader specifies valid url schemes" do
            before do
              subject.video.stub(:url_scheme_white_list).and_return(%w{http https})
            end

            context "and the url's scheme is included in the list" do
              before do
                subject.remote_video_net_url = "https://example.com/some_video.mp3"
              end

              it "should be valid" do
                subject.should be_valid
              end
            end

            context "but the url's scheme is not included in the list" do
              before do
                subject.remote_video_net_url = "ftp://example.com/some_video.mp3"
              end

              it "should not be valid" do
                subject.should_not be_valid
              end

              it_should_behave_like "a remote net url i18n error message" do
                let(:i18n_options) { {:url_scheme_white_list => %w{http https} } }
              end

              it "should include the white listed url schemes in the error message" do
                subject.valid?
                subject.errors[:video].first.should include("http and https")
              end
            end
          end
        end

        context "on update" do
          before do
            subject.remote_video_net_url = "http$://example.com/some_video.mp4"
          end

          it "should be valid" do
            subject.save(:validate => false)
            subject.should be_valid
          end
        end
      end
    end

    describe ".validates_filename_uniqueness_of" do
      before do
        party_class.validates_filename_uniqueness_of :video
      end

      it_should_behave_like "validating uniqueness of filenames"
    end

    describe ".validate :video, :unique_filename => true" do
      before do
        party_class.validates :video, :unique_filename => true
      end

      it_should_behave_like "validating uniqueness of filenames"
    end

    describe ".validates_filename_format_of" do
      before do
        party_class.validates_filename_format_of :video
      end

      it_should_behave_like "validating format of filenames"
    end

    describe ".validate :video, :filename_format => true" do
      before do
        party_class.validates :video, :filename_format => true
      end

      it_should_behave_like "validating format of filenames"
    end

    describe ".validates_remote_net_url_format_of" do
      before do
        party_class.validates_remote_net_url_format_of :video
      end

      it_should_behave_like "validating format of remote net urls"
    end

    describe ".validate :video, :remote_net_url_format => true" do
      before do
        party_class.validates :video, :remote_net_url_format => true
      end

      it_should_behave_like "validating format of remote net urls"
    end

    describe "#key" do
      it "should be accessible" do
        party_class.new(:key => "some key").key.should == "some key"
      end
    end

    describe "#remote_\#\{column\}_net_url" do
      it "should be accessible" do
        party_class.new(:remote_video_net_url => "some url").remote_video_net_url.should == "some url"
      end
    end

    describe "#filename_valid?" do
      shared_examples_for "having empty errors" do
        before { subject.filename_valid? }

        context "where after the call, #errors" do
          it "should be empty" do
            subject.errors.should be_empty
          end
        end
      end

      context "with filename validations turned off" do
        context "with an invalid key" do
          before do
            subject.key = sample_key(:model_class => subject.class, :valid => false)
          end

          it "should be true" do
            subject.filename_valid?.should be_true
          end
        end
      end

      context "with filename validations on" do
        before do
          party_class.validates_filename_format_of :video
        end

        context "does not have a video upload" do
          it "should be true" do
            subject.filename_valid?.should be_true
          end

          it_should_behave_like "having empty errors"
        end

        context "has a video upload" do
          context "with a valid filename" do
            before { subject.key = sample_key(:model_class => subject.class) }

            it "should be true" do
              subject.filename_valid?.should be_true
            end

            it_should_behave_like "having empty errors"
          end

          context "with an invalid filename" do
            before { subject.key = sample_key(:model_class => subject.class, :valid => false) }

            it "should be false" do
              subject.filename_valid?.should be_false
            end

            context "after the call, #errors" do
              before { subject.filename_valid? }

              it "should only contain 'video' errors" do
                subject.errors.count.should == subject.errors[:video].count
              end
            end
          end
        end
      end
    end
  end
end

