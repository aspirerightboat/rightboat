ActiveAdmin.register BoatImage do
  config.batch_actions = false
  config.sort_order = 'position_asc'

  permit_params :source_url, :file, :position, :kind, :caption, :layout_image_id, :layout_mark_info

  menu parent: 'Boats', priority: 20

  filter :boat_id, label: 'Boat ID'
  filter :position
  filter :width
  filter :height

  index as: :grid, columns: 6 do |i|
    @primary ||= :yes
    img_style = ''
    img_style << 'opacity: 0.5; border: 1px solid red;' if i.deleted?
    img_style << 'border: 2px solid lime;' if @primary == :yes
    @primary = :no
    img = image_tag(i.file.url(:mini), style: img_style)
    s = link_to(img, i.file.url, title: "Original: #{i.width}x#{i.height}")
    s << '<br>'.html_safe
    s << "#{i.position} | ".html_safe
    s << link_to('View', [:admin, i]); s << ' | '
    s << link_to('Edit', [:edit, :admin, i]); s << ' | '
    if i.deleted?
      s << link_to('Act', [:undelete, :admin, i], method: :post); s << ' | '
    else
      s << link_to('Hide', [:admin, i], method: :delete); s << ' | '
    end
    s << link_to('◄', [:dec_pos, :admin, i], method: :post); s << ' | '
    s << link_to('►', [:inc_pos, :admin, i], method: :post)
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
      link_to i.boat.id, admin_boat_path(i.boat)
    end
    column :width
    column :height

    actions
  end

  form do |f|
    f.inputs do
      f.input :source_url
      f.input :file, as: :file, hint: (image_tag(f.object.file_url, alt: '', style: 'max-height: 150') if f.object.file.present?)
      f.input :position
      f.input :kind, as: :select, collection: BoatImage.kinds.keys, include_blank: false
      f.input :caption
      f.input :layout_image_id, as: :select, collection: f.object.boat.boat_images.layout
      f.input :layout_mark_info
      f.input :http_last_modified
      f.input :width
      f.input :height
      f.input :content_type
      f.input :http_etag
      f.input :downloaded_at
      f.input :deleted_by_user_id
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
      end_of_association_chain.order(:position, :id)
    end
  end

  sidebar 'Boat Tools', only: [:index] do
    if (boat_id = params.dig(:q, :boat_id_equals)).present?
      para { link_to 'View boat', admin_boat_path(Boat.find(boat_id)) }
      para { link_to 'Deactivate boat images', {action: :delete_boat_images, boat_id: boat_id}, method: :post,
                     class: 'button', data: {disable_with: 'working...', confirm: 'Are you sure?'} }
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

  member_action :destroy, method: :delete do
    i = BoatImage.find(params[:id])
    i.update(deleted_at: Time.now, deleted_by_user_id: current_user.id)
    redirect_to request.referer || admin_boat_images_path
  end

  member_action :undelete, method: :post do
    i = BoatImage.find(params[:id])
    i.update(deleted_at: nil, deleted_by_user_id: nil)
    redirect_to request.referer || admin_boat_images_path
  end

  collection_action :delete_boat_images, method: :post do
    boat = Boat.find(params[:boat_id])
    boat.boat_images.update_all(deleted_at: Time.now, deleted_by_user_id: current_user.id)
    redirect_to request.referer || admin_boat_images_path, notice: "#{boat.boat_images.count} images deactivated"
  end

end
