ActiveAdmin.register HomeSetting do
  permit_params :boat_type, :attached_media
  menu parent: 'Other'

  index do
    column :boat_type
    column :attached_media do |setting|
      image_tag(setting.attached_media.url, size: '64x43')
    end
    actions
  end
end
