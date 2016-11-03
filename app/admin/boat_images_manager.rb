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
    before_action :load_boat, only: [:index, :upload_images, :remove_image, :move_image]

    def index

      @images_by_kind = @boat.boat_images.group_by(&:kind)
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

    render json: {images: boat_images.map { |bi| {id: bi.id, mini_url: bi.file_url(:thumb), url: bi.file_url} }}
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

    prev_pos = bi_prev&.position || 0
    next_pos = bi_next&.position || 0
    bi.position = (prev_pos + next_pos) / 2
    bi.position = prev_pos + 1 if bi.position <= prev_pos
    bi.update_column(:position, bi.position)

    if bi.position >= next_pos
      if next_pos > prev_pos
        @boat.boat_images.where('position >= ?', next_pos).where('id <> ?', bi.id).update_all('position = position + 10')
      else
        image_ids = @boat.boat_images.pluck(:id).drop_while { |bi_id| bi_id != bi_next&.id }.select { |bi_id| bi_id != bi.id }
        BoatImage.where(id: image_ids).update_all('position = position + 10') if image_ids.any?
      end
    end

    head :ok
  end

end
