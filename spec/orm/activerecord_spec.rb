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
    include UploaderHelpers

    let(:subject) { Party.new }

    shared_examples_for "validating uniqueness of filenames" do
      context "a Party with a mounted video exists" do
        before do
          subject.video.key = "bliind"
          subject.save
        end

        context "another Party with a duplicate video filename" do
          let(:another_party) do
            another_party = Party.new
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

    describe ".validates_filename_uniqueness_of" do
      before do
        Party.instance_eval do
          validates_filename_uniqueness_of :video
        end
      end

      it_should_behave_like "validating uniqueness of filenames"
    end

    describe ".validate :video, :unique_filename => true" do
      before do
        Party.instance_eval do
          validates :video, :unique_filename => true
        end
      end

      it_should_behave_like "validating uniqueness of filenames"
    end

    describe "#key" do
      it "should be accessible" do
        subject.class.new(:key => "some key").key.should == "some key"
      end
    end

    describe "#remote_\#\{column\}_net_url" do
      it "should be accessible" do
        subject.class.new(:remote_video_net_url => "some url").remote_video_net_url.should == "some url"
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
            subject.errors.clear
          end

          it "should be true" do
            subject.filename_valid?.should be_true
          end
        end
      end

      context "with filename validations on" do
        before do
          Party.instance_eval do
            validates :video, :filename_format => true
          end
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

