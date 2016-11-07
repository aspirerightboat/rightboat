ActiveAdmin.register Image do

  menu parent: 'Other', label: 'Images'

  permit_params :file, :filename, :slug

  config.sort_order = 'created_at_desc'
  config.filters = false

  index do
    column :thumb do |image|
      image_tag image.file.url(:thumb), alt: image.file.filename
    end
    column 'URL' do |image|
      link_to image.file_url, image.file_url, target: '_blank'
    end
    column :created_at
    actions
  end
end
