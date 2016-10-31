ActiveAdmin.register_page 'Boat Images Manager' do
  menu parent: 'Boats', priority: 30

  content title: 'Boat Images Manager' do
    render partial: 'index'
  end

  breadcrumb do
    boat = Boat.find(params[:boat_id])
    [
        link_to('Admin', '/admin'),
        link_to('Boats', '/admin/boats'),
        link_to(boat.slug, "/admin/boats/#{boat.slug}"),
    ]
  end

  controller do
    def index
      @boat = Boat.find(params[:boat_id])
      @images_by_kind = @boat.boat_images.group_by(&:kind)
    end
  end

end
