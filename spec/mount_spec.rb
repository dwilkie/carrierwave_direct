# encoding: utf-8

require 'spec_helper'

describe CarrierWaveDirect::Mount do
  include ModelHelpers

  class Gathering
    extend CarrierWave::Mount
    extend CarrierWaveDirect::Mount
    mount_uploader :video, DirectUploader
  end

  context "class Gathering; extend CarrierWave::Mount; extend CarrierWaveDirect::Mount; mount_uploader :video, DirectUploader; end" do
    let(:subject) { Gathering.new }

    it_should_have_accessor(:remote_video_net_url)

    describe "#has_video_upload?" do
      context "video does not have a key" do
        before { subject.video.stub(:has_key?).and_return(false) }

        it "should return false" do
          subject.should_not have_video_upload
        end
      end

      context "video has a key" do
        before { subject.video.stub(:has_key?).and_return(true) }

        it "should return true" do
          subject.should have_video_upload
        end
      end
    end

    describe "#has_remote_video_net_url?" do
      context "remote_video_net_url is nil" do
        before { subject.remote_video_net_url = nil }

        it "should return false" do
          subject.should_not have_remote_video_net_url
        end
      end

      context "remote_video_net_url is not nil" do
        before { subject.remote_video_net_url = "something" }

        it "should return true" do
          subject.should have_remote_video_net_url
        end
      end
    end

    it_should_delegate(:key, :to => "video#key", :accessible => {"has_video_upload?" => false})

  end
end

