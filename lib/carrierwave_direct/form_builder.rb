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

    def content_type_select(choices = [], selected = nil, options = {})
      hidden_fields <<
      @template.select_tag('Content-Type', content_choices_options(choices, selected), options)
    end

    def hidden_fields
      return ''.html_safe if @hidden_fields_emitted

      @hidden_fields_emitted = true
      hidden_field(:content_type,                    :name => 'Content-Type') <<
      hidden_field(:key,                             :name => "key") <<
      hidden_field(:aws_access_key_id,               :name => "AWSAccessKeyId") <<
      hidden_field(:acl,                             :name => "acl") <<
      hidden_field(:success_action_redirect,         :name => "success_action_redirect") <<
      hidden_field(:policy,                          :name => "policy") <<
      hidden_field(:signature,                       :name => "signature")
    end

    private

    def content_choices_options(choices, selected = nil)
      choices = %w(application/atom+xml application/ecmascript application/json application/javascript application/octet-stream application/ogg application/pdf application/postscript application/rss+xml application/font-woff application/xhtml+xml application/xml application/xml-dtd application/zip application/gzip audio/basic audio/mp4 audio/mpeg audio/ogg audio/vorbis audio/vnd.rn-realaudio audio/vnd.wave audio/webm image/gif image/jpeg image/pjpeg image/png image/svg+xml image/tiff text/cmd text/css text/csv text/html text/javascript text/plain text/vcard text/xml video/mpeg video/mp4 video/ogg video/quicktime video/webm video/x-matroska video/x-ms-wmv video/x-flv) if choices.blank?
      selected ||= @object.content_type
      @template.options_for_select(choices,selected)
    end
  end
end

