ActiveAdmin.register BoatImage do
  config.batch_actions = false
  config.sort_order = 'position_asc'

  permit_params :source_url, :file, :position

  menu parent: 'Boats', priority: 20

  filter :boat_id, label: 'Boat ID'
  filter :position
  filter :width
  filter :height

  index as: :grid, columns: 6 do |i|
    s = link_to(image_tag(i.file.url(:mini)), i.file.url, title: "Original: #{i.width}x#{i.height}")
    s << '<br>'.html_safe
    s << "#{i.position} | ".html_safe
    s << link_to('View', admin_boat_image_path(i)); s << ' | '
    s << link_to('Edit', edit_admin_boat_image_path(i)); s << ' | '
    if i.deleted?
      s << link_to('Undel', undelete_admin_boat_image_path(i), method: :post); s << ' | '
    else
      s << link_to('Del', admin_boat_image_path(i), method: :delete); s << ' | '
    end
    s << link_to('◄', dec_pos_admin_boat_image_path(i), method: :post); s << ' | '
    s << link_to('►', inc_pos_admin_boat_image_path(i), method: :post)
    s
  end

  index do
    column :source do |i|
      link_to('source_url', i.source_url)
    end
    column :image do |i|
      link_to image_tag(i.file.url(:mini)), i.file.url
    end
    column :position
    column :boat do |i|
      link_to i.boat.id, i.boat
    end
    column :width
    column :height

    actions
  end

  form do |f|
    f.inputs do
      f.input :source_url
      f.input :file, as: :file
      f.input :position
    end
    actions
  end

  show do
    default_main_content
    panel 'Tools' do
      link_to 'Show this boat images', admin_boat_images_path(q: {boat_id_equals: boat_image.boat_id})
    end
  end

  controller do
    def scoped_collection
      end_of_association_chain.order(:position)
    end
  end

  sidebar 'Boat Tools', only: [:index] do
    if (boat_id = (params[:q] && params[:q][:boat_id_equals])).present?
      s = '<p>'
      s << link_to('View boat', admin_boat_path(Boat.find(boat_id)))
      s << '</p><p>'
      s << link_to('Delete boat images', {action: :delete_boat_images, boat_id: boat_id}, method: :post, class: 'button', data: {disable_with: 'working...', confirm: 'Are you sure?'})
      s << '</p>'
      s.html_safe
    end
  end

  member_action :inc_pos, method: :post do
    i = BoatImage.find(params[:id])
    i.update_attribute(:position, (i.position || 0) + 1)
    redirect_to request.referer || admin_boat_images_path
  end

  member_action :dec_pos, method: :post do
    i = BoatImage.find(params[:id])
    i.update_attribute(:position, (i.position || 0) - 1)
    redirect_to request.referer || admin_boat_images_path
  end

  member_action :undelete, method: :post do
    i = BoatImage.find(params[:id])
    i.revive
    redirect_to request.referer || admin_boat_images_path
  end

  collection_action :delete_boat_images, method: :post do
    boat = Boat.find(params[:boat_id])
    cnt = boat.boat_images.destroy_all.size
    redirect_to request.referer || admin_boat_images_path, notice: "#{cnt} images destroyed"
  end

end
