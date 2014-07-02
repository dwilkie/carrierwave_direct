# encoding: utf-8
#
require 'spec_helper'
require 'data/sample_data'

describe CarrierWaveDirect::Uploader::DirectUrl do

  let(:subject) { DirectUploader.new }

  describe "#direct_fog_url" do
    it "should return the result from CarrierWave::Storage::Fog::File#public_url" do
      expect(subject.direct_fog_url).to eq CarrierWave::Storage::Fog::File.new(
        subject, nil, nil
      ).public_url
    end

    context ":with_path => true" do

      context "#key is set to '#{sample(:path_with_special_chars)}'" do
        before { subject.key = sample(:path_with_special_chars) }

        it "should return the full url with '/#{URI.escape(sample(:path_with_special_chars))}' as the path" do
          direct_fog_url = CarrierWave::Storage::Fog::File.new(
            subject, nil, nil
          ).public_url
          expect(subject.direct_fog_url(:with_path => true)).to eq direct_fog_url + "#{URI.escape(sample(:path_with_special_chars))}"
        end
      end

      context "#key is set to '#{sample(:path_with_escaped_chars)}'" do
        before { subject.key = sample(:path_with_escaped_chars) }

        it "should return the full url with '/#{sample(:path_with_escaped_chars)}' as the path" do
          direct_fog_url = CarrierWave::Storage::Fog::File.new(
            subject, nil, nil
          ).public_url
          expect(subject.direct_fog_url(:with_path => true)).to eq direct_fog_url + sample(:path_with_escaped_chars)
        end
      end

      context "#key is set to '#{sample(:path)}'" do
        before { subject.key = sample(:path) }

        it "should return the full url with '/#{sample(:path)}' as the path" do
          direct_fog_url = CarrierWave::Storage::Fog::File.new(
            subject, nil, nil
          ).public_url
          expect(subject.direct_fog_url(:with_path => true)).to eq direct_fog_url + "#{sample(:path)}"
        end
      end
    end
  end

  describe "#asset_host" do
    it "should return nil" do
      subject.class.configure do |config|
        config.asset_host = "http://foo.bar"
      end

      expect(subject.asset_host).to be_nil
    end
  end

end

