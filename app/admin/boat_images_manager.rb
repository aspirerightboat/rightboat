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
    before_action :load_boat

    def index
      @kind_separated_images = Rightboat::BoatImagesKindSeparated.new(@boat)
    end

    private

    def load_boat
      @boat = Boat.find(params[:boat_id])
    end
  end

  page_action :upload_images, method: :post do
    max_pos = @boat.boat_images.maximum(:position) || 0


    boat_images = params[:files].map do |file|
      @boat.boat_images.create(file: file, position: (max_pos += 10))
    end

    render json: {images: boat_images.map { |bi| bi.small_props_hash }}
  end

  page_action :remove_image, method: :post do
    bi = @boat.boat_images.find(params[:image])

    if bi.destroy
      head :ok
    else
      head :bad_request
    end
  end

  page_action :move_image, method: :post do
    bi = @boat.boat_images.find(params[:image])
    bi_prev = (@boat.boat_images.find(params[:prev]) if params[:prev].present?)
    bi_next = (@boat.boat_images.find(params[:next]) if params[:next].present?)
    layout_image = (@boat.boat_images.find(params[:layout_image]) if params[:layout_image])

    bi.kind = params[:kind]
    bi.layout_image = layout_image

    rel = @boat.boat_images
    rel = rel.where(layout_image: layout_image) if layout_image
    bi.move_between(bi_prev, bi_next, rel)
    bi.save!

    head :ok
  end

  page_action :update_caption, method: :post do
    bi = @boat.boat_images.find(params[:image])
    bi.caption = params[:caption]
    bi.save!

    head :ok
  end

end
