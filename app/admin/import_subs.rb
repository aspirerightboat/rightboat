ActiveAdmin.register ImportSub do
  menu parent: 'Imports', label: 'Substitutions', priority: 20

  permit_params :import_type,  :import_id,  :remove_regex,  :sample_text

  filter :import_type, collection: -> { ['any'] + Rightboat::Imports::Base.import_types }
  filter :import_id

  index do
    column :import_type do |is|
      is.import_type.presence || 'any'
    end
    column :import_id do |is|
      is.import_id.presence || 'any'
    end
    column :remove_regex do |is|
      b { is.remove_regex }
    end
    column :sample_text do |is|
      truncate is.sample_text, length: 30
    end
    column :created_at
    column :updated_at

    actions
  end

  form do |f|
    f.inputs do
      f.input :import_type, as: :select, include_blank: 'any',
              collection: Rightboat::Imports::Base.import_types,
              input_html: {class: 'sync-select', data: {target: 'import-id-list',
                                                        action: url_for(action: :import_id_by_type),
                                                        include_blank: 'any'}}
      f.input :import_id, as: :select, include_blank: 'any',
              collection: import_id_options(f.object.import_type),
              input_html: {class: 'import-id-list'}
      f.input :remove_regex
      f.input :sample_text #, input_html: {rows: 5}
    end
    actions
  end

  show do
    default_main_content
    panel 'Remove Regex Result' do
      regex = Regexp.new(resource.remove_regex) rescue RegexpError
      if regex == RegexpError
        '<b style="color:red">REGEX ERROR</b>'.html_safe
      else
        resource.sample_text.gsub(regex, '')
      end
    end
  end

  controller do
    include ActiveAdmin::ImportStubsHelper
  end

  collection_action :import_id_by_type do
    render json: import_id_options(params[:id]), root: false
  end

end
