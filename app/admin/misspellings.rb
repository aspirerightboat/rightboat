ActiveAdmin.register Misspelling do
  controller do
    belongs_to :manufacturer, polymorphic: true, optional: true
    belongs_to :country, polymorphic: true, optional: true
    belongs_to :specification, polymorphic: true, optional: true
    belongs_to :model, polymorphic: true, optional: true
    belongs_to :engine_manufacturer, polymorphic: true, optional: true
    belongs_to :engine_model, polymorphic: true, optional: true
    belongs_to :vat_rate, polymorphic: true, optional: true
  end

  config.sort_order = 'alias_string_asc'
  menu priority: 10

  permit_params :alias_string, :source_type, :source_id

  filter :alias_string, label: 'Name'
  filter :source_type

  index do
    column :name do |record|
      record.alias_string

    end
    column :source_type
    column :source
    actions
  end

  form do |f|
    f.inputs do
      f.input :alias_string, label: "Name"
    end
    f.actions
  end

end
