# encoding: utf-8
#
require 'spec_helper'
require 'data/sample_data'

describe CarrierWaveDirect::Uploader::DirectUrl do

  let(:subject) { DirectUploader.new }

  let(:mounted_subject) { DirectUploader.new(mounted_model, sample(:mounted_as)) }

  describe "#direct_fog_url" do
    it "should return the result from CarrierWave::Storage::AWSFile#public_url" do
      expect(subject.direct_fog_url).to eq CarrierWave::Storage::AWSFile.new(
        subject, nil, nil
      ).public_url
    end

    context ":with_path => true" do
      it "should return the full url set by carrierwave" do
        allow(subject).to receive(:url).and_return("url")
        expect(subject.direct_fog_url(:with_path => true)).to eq "url"
      end
    end
  end
end
