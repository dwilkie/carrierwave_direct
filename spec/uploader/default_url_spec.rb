# encoding: utf-8
#
require 'spec_helper'
require 'data/sample_data'

describe CarrierWaveDirect::Uploader::DirectUrl do

  let(:subject) { DirectUploader.new }

  describe "#default_url" do
    context "#key is not set" do
      it "should return nil" do
        expect(subject.default_url).to eq nil
      end
    end

    context "#key is not a defined method" do
      before { subject.stub(:respond_to?).with(:has_key?).and_return(false) }

      it "should return nil" do
        expect(subject.default_url).to eq nil
      end
    end

    context "#key is set to '#{sample(:path)}'" do
      before { subject.key = sample(:path) }

      it "should return the result from CarrierWave::Storage::Fog::File#url" do
        expect(
          subject.default_url
        ).to eq CarrierWave::Storage::Fog::File.new( subject, nil, sample(:path)).url
      end
    end
  end

end

