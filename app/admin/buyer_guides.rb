ActiveAdmin.register BuyerGuide do

  menu parent: 'Other'

  permit_params :photo, :photo_cache, :thumbnail, :thumbnail_cache, :article_author_id, :manufacturer_id,
                :model_id, :body, :short_description, :zcard_desc, :published

  scope :published

  filter :author
  filter :manufacturer

  index do
    column :manufacturer
    column :model
    column :author
    column :photo do |guide|
      image_tag guide.photo_url(:thumb)
    end
    column :short_description
    column :published
    column :created_at
    column :updated_at
    actions
  end

  form do |f|
    f.inputs 'Details' do
      f.input :photo, as: :file, hint: image_tag(f.object.photo_url(:thumb))
      f.input :photo_cache, as: :hidden
      f.input :thumbnail, as: :file, hint: image_tag(f.object.thumbnail_url(:thumb))
      f.input :thumbnail_cache, as: :hidden
      f.input :author
      f.input :manufacturer, collection: Manufacturer.order('name ASC'), include_blank: false
      f.input :model, collection: Model.order('name ASC'), include_blank: false
      f.input :short_description
      f.input :zcard_desc, as: :text, input_html: {rows: 5}
      f.input :body
      f.input :published
    end
    f.actions
  end

  member_action :models do
    manufacturer = Manufacturer.where(id: params[:manufacturer]).first
    models = manufacturer.models.order(:name)
    options = self.view_context.options_from_collection_for_select(models, :id, :name, resource.model_id)
    render text: options
  end
end
