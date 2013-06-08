# encoding: utf-8

require 'spec_helper'

shared_examples_for 'hidden values form' do
  hidden_fields = [
                    :key,
                    {:aws_access_key_id => "AWSAccessKeyId"},
                    :acl,
                    :success_action_redirect,
                    :policy,
                    :signature,
                    {:content_type => 'Content-Type'}
                  ]

  hidden_fields.each do |input|
    if input.is_a?(Hash)
      key = input.keys.first
      name = input[key]
    else
      key = name = input
    end

    it "should have a hidden field for '#{name}'" do
      direct_uploader.stub(key).and_return(key.to_s)
      subject.should have_input(
        :direct_uploader,
        key,
        :type => :hidden,
        :name => name,
        :value => key,
        :required => false
      )
    end
  end
end

describe CarrierWaveDirect::FormBuilder do
  include FormBuilderHelpers

  describe "#file_field" do

    def form_with_file_field
      form {|f| f.file_field :video }
    end


    # http://aws.amazon.com/articles/1434?_encoding=UTF8
    context "form" do
      let(:subject) {form_with_file_field}
      it_should_behave_like 'hidden values form'


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

  describe "#content_type_select" do
    context "form" do
      let(:subject) do
        form {|f| f.content_type_select }
      end

      it_should_behave_like 'hidden values form'
    end
  end

  describe "#content_type_label" do
    context "form" do
      let(:subject) do
        form {|f| f.content_type_label }
      end

      it_should_behave_like 'hidden values form'
    end
  end

  describe 'full form' do
    before {direct_uploader.stub('key').and_return('foo')}
    let(:dom) do
      form do |f|
        f.content_type_label <<
        f.content_type_select <<
        f.file_field(:video)
      end
    end

    it 'should only include the hidden values once' do
      dom.should have_input(
                   :direct_uploader,
                   'key',
                   :type => :hidden,
                   :name => 'key',
                   :value => 'foo',
                   :required => false,
                   :count => 1
                 )
    end

    it 'should include Content-Type twice' do
      puts dom.inspect
      dom.should have_input(
                   :direct_uploader,
                   :content_type,
                   :type => :hidden,
                   :name => 'Content-Type',
                   :value => 'binary/octet-stream',
                   :required => false,
                   :count => 1
                 )

      dom.should have_selector :xpath, './/select[@name="Content-Type"]', :count => 1
    end
  end
end
