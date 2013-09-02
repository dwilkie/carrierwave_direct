# encoding: utf-8

module CarrierWaveDirect
  class FormBuilder < ActionView::Helpers::FormBuilder
    def file_field(method, options = {})
      options.merge!(:name => "file")
      fields = hidden_fields

      if options[:use_action_status]
        fields << hidden_field(:success_action_status, :name => "success_action_status")
      else
        fields << hidden_field(:success_action_redirect, :name => "success_action_redirect")
      end

      fields << super
    end

    def content_type_label(content=nil)
      content ||= 'Content Type'
      hidden_fields <<
      @template.label_tag('Content-Type', content)
    end

    def content_type_select(choices = [], selected = nil, options = {})
      hidden_fields <<
      @template.select_tag('Content-Type', content_choices_options(choices, selected), options)
    end

    def hidden_fields
      return ''.html_safe if @hidden_fields_emitted

      @hidden_fields_emitted = true
      fields =  hidden_field(:content_type,            :name => 'Content-Type')
      fields << hidden_field(:key,                     :name => "key")
      fields << hidden_field(:aws_access_key_id,       :name => "AWSAccessKeyId")
      fields << hidden_field(:acl,                     :name => "acl")
      fields << hidden_field(:success_action_redirect, :name => "success_action_redirect")
      fields << hidden_field(:policy,                  :name => "policy")
      fields << hidden_field(:signature,               :name => "signature")
      fields
    end

    private

    def content_choices_options(choices, selected = nil)
      choices = @object.content_types if choices.blank?
      selected ||= @object.content_type
      @template.options_for_select(choices,selected)
    end
  end
end
