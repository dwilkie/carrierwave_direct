# encoding: utf-8

module CarrierWaveDirect
  class FormBuilder < ActionView::Helpers::FormBuilder
    def file_field(method, options = {})
      options.merge!(:name => "file")
      hidden_fields <<
      super
    end

    def content_type_label(content=nil)
      content ||= 'Content Type'
      hidden_fields <<
      @template.label_tag('Content-Type', content)
    end

    def content_type_select(choices = [], options = {})
      puts @template.class.inspect
      hidden_fields <<
      @template.select_tag('Content-Type', @template.options_for_select(choices,@object.content_type), options)
    end

    def hidden_fields
      puts 'hidden_fields'
      return ''.html_safe if @hidden_fields_emitted

      puts 'hidden fields emitting'

      @hidden_fields_emitted = true
      hidden_field(:content_type,                    :name => 'Content-Type') <<
      hidden_field(:key,                             :name => "key") <<
      hidden_field(:aws_access_key_id,               :name => "AWSAccessKeyId") <<
      hidden_field(:acl,                             :name => "acl") <<
      hidden_field(:success_action_redirect,         :name => "success_action_redirect") <<
      hidden_field(:policy,                          :name => "policy") <<
      hidden_field(:signature,                       :name => "signature")
    end
  end
end

