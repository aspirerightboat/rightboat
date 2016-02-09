ActiveAdmin.register ImportSub do
  menu parent: 'Imports', label: 'Substitutions', priority: 20

  permit_params :import_type,  :import_id,  :use_regex, :from, :to,  :sample_text

  filter :import_type, collection: -> { ['any'] + Rightboat::Imports::ImporterBase.import_types }
  filter :import_id

  index do
    column :import_type do |is|
      is.import_type.presence || 'any'
    end
    column :import_id do |is|
      is.import_id.presence || 'any'
    end
    column :use_regex
    column :from do |is|
      b { is.from }
    end
    column :to do |is|
      b { is.to }
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
              collection: Rightboat::Imports::ImporterBase.import_types,
              input_html: {class: 'sync-select', data: {target: 'import-id-list',
                                                        action: url_for(action: :import_id_by_type),
                                                        include_blank: 'any'}}
      f.input :import_id, as: :select, include_blank: 'any',
              collection: import_id_options(f.object.import_type),
              input_html: {class: 'import-id-list'}
      f.input :use_regex
      f.input :from
      f.input :to
      f.input :sample_text #, input_html: {rows: 5}
    end
    actions
  end

  show do
    attributes_table do
      row :import_type
      row :import_id
      row :use_regex
      row :from do
        pre { import_sub.from }
      end
      row :to do
        pre { import_sub.to }
      end
      row :sample_text
      row :created_at
      row :updated_at
    end
    panel 'Substitution Result' do
      res = resource.processed_sample rescue RegexpError
      if res == RegexpError
        '<b style="color:red">REGEX ERROR</b>'.html_safe
      else
        res
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
