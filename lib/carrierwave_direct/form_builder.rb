# encoding: utf-8

module CarrierWaveDirect
  class FormBuilder < ActionView::Helpers::FormBuilder
    def file_field(method, options = {})
      options.merge!(:name => "file")
      fields = hidden_field(:key, :name => "key")
      fields << hidden_field(:aws_access_key_id, :name => "AWSAccessKeyId")
      fields << hidden_field(:acl, :name => "acl")
      fields << hidden_field(:policy, :name => "policy")
      fields << hidden_field(:signature, :name => "signature")

      if options[:use_action_status]
        fields << hidden_field(:success_action_status, :name => "success_action_status")
      else
        fields << hidden_field(:success_action_redirect, :name => "success_action_redirect")
      end

      fields << super
    end
  end
end

