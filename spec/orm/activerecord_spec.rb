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

  shared_examples_for "validating uniqueness of filenames" do
    context "a party with a mounted video exists" do
      let(:party) do
        party = Party.new
        party.video.key = "bliind"
        party.save
        party
      end

      context "another party with a duplicate video filename" do
        let(:another_party) do
          another_party = Party.new
          another_party.video.key = party.video.key
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

  describe ".validates_filename_uniqueness_of # e.g. :video" do
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

  describe "accessible attibutes" do
    describe "#key" do
      it "should be accessible" do
        party = Party.new(:key => "some key")
        party.key.should == "some key"
      end
    end

    describe "#remote_\#\{column\}_net_url" do
      it "should be accessible" do
        party = Party.new(:remote_video_net_url => "some url")
        party.remote_video_net_url.should == "some url"
      end
    end
  end
end

