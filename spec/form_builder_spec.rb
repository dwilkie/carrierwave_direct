# encoding: utf-8

require 'spec_helper'

describe CarrierWaveDirect::FormBuilder do
  include FormBuilderHelpers

  describe "#file_field" do

    def form_with_file_field
      form {|f| f.file_field :video }
    end

    hidden_fields = [
                      :key,
                      {:aws_access_key_id => "AWSAccessKeyId"},
                      :acl,
                      :success_action_redirect,
                      :policy,
                      :signature
                    ]

    # http://aws.amazon.com/articles/1434?_encoding=UTF8
    context "form" do

      hidden_fields.each do |input|
        if input.is_a?(Hash)
          key = input.keys.first
          name = input[key]
        else
          key = name = input
        end

        it "should have a hidden field for '#{name}'" do
          direct_uploader.stub(key).and_return(key.to_s)
          form_with_file_field.should have_input(
            :direct_uploader,
            key,
            :type => :hidden,
            :name => name,
            :value => key,
            :required => false
          )
        end
      end

      it "should have an input for a file to upload" do
        form_with_file_field.should have_input(
          :direct_uploader,
          :video,
          :type => :file,
          :name => :file,
          :required => false
        )
      end
    end
  end
end

