# encoding: utf-8

require 'spec_helper'

class CarrierWaveDirect::FormBuilder
  attr_reader :template
  public :content_choices_options
end

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

    def form_with_default_file_field
      form {|f| f.file_field :video }
    end

    def form_with_file_field_and_no_redirect
      form {|f| f.file_field :video, use_action_status: true }
    end

    default_hidden_fields = [
                      :key,
                      {:aws_access_key_id => "AWSAccessKeyId"},
                      :acl,
                      :success_action_redirect,
                      :policy,
                      :signature
                    ]
    status_hidden_fields = [
                      :key,
                      {:aws_access_key_id => "AWSAccessKeyId"},
                      :acl,
                      :success_action_status,
                      :policy,
                      :signature
                    ]

    # http://aws.amazon.com/articles/1434?_encoding=UTF8
    context "form" do
      let(:subject) {form_with_default_file_field}
      it_should_behave_like 'hidden values form'

      default_hidden_fields.each do |input|
        if input.is_a?(Hash)
          key = input.keys.first
          name = input[key]
        else
          key = name = input
        end

        it "should have a hidden field for '#{name}'" do
          direct_uploader.stub(key).and_return(key.to_s)
          form_with_default_file_field.should have_input(
            :direct_uploader,
            key,
            :type => :hidden,
            :name => name,
            :value => key,
            :required => false
          )
        end
      end

      status_hidden_fields.each do |input|
        if input.is_a?(Hash)
          key = input.keys.first
          name = input[key]
        else
          key = name = input
        end

        it "should have a hidden field for '#{name}'" do
          direct_uploader.stub(key).and_return(key.to_s)
          form_with_file_field_and_no_redirect.should have_input(
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
        form_with_default_file_field.should have_input(
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

      it 'should select the default content type' do
        direct_uploader.stub(:content_type).and_return('video/mp4')
        subject.should have_content_type 'video/mp4', true
      end

      it 'should select the passed in content type' do
        dom = form {|f| f.content_type_select nil, 'video/mp4'}
        dom.should have_content_type 'video/mp4', true
      end

      it 'should include most content types' do
        %w(application/atom+xml application/ecmascript application/json application/javascript application/octet-stream application/ogg application/pdf application/postscript application/rss+xml application/font-woff application/xhtml+xml application/xml application/xml-dtd application/zip application/gzip audio/basic audio/mp4 audio/mpeg audio/ogg audio/vorbis audio/vnd.rn-realaudio audio/vnd.wave audio/webm image/gif image/jpeg image/pjpeg image/png image/svg+xml image/tiff text/cmd text/css text/csv text/html text/javascript text/plain text/vcard text/xml video/mpeg video/mp4 video/ogg video/quicktime video/webm video/x-matroska video/x-ms-wmv video/x-flv).each do |type|
          subject.should have_content_type type
        end
      end
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
