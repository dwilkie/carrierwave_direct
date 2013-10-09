# encoding: utf-8

module CarrierWaveDirect
  class FormBuilder < ActionView::Helpers::FormBuilder
    def file_field(method, options = {})
      options.merge!(:name => "file")

      fields = required_base_fields

      fields << content_type_field(options)

      fields << success_action_field(options)

      # The file field must be the last element in the form.
      # Any element after this will be ignored by Amazon.
      fields << super
    end

    def content_type_label(content=nil)
      content ||= 'Content Type'
      @template.label_tag('Content-Type', content)
    end

    def content_type_select(choices = [], selected = nil, options = {})
      @template.select_tag('Content-Type', content_choices_options(choices, selected), options)
    end

    private

    def required_base_fields
      hidden_field(:key,                     :name => "key") <<
      hidden_field(:aws_access_key_id,       :name => "AWSAccessKeyId") <<
      hidden_field(:acl,                     :name => "acl") <<
      hidden_field(:policy,                  :name => "policy") <<
      hidden_field(:signature,               :name => "signature")
    end

    def content_type_field(options)
      return ''.html_safe unless @object.will_include_content_type

      hidden_field(:content_type, :name => 'Content-Type') unless options[:exclude_content_type]
    end

    def success_action_field(options)
      if @object.use_action_status
        hidden_field(:success_action_status, :name => "success_action_status")
      else
        hidden_field(:success_action_redirect, :name => "success_action_redirect")
      end
    end

    def content_choices_options(choices, selected = nil)
      choices = @object.content_types if choices.blank?
      selected ||= @object.content_type
      @template.options_for_select(choices, selected)
    end
  end
end
