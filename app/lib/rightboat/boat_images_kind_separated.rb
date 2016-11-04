module Rightboat
  class BoatImagesKindSeparated
    attr_reader :regular_images, :images_by_layout_image, :side_view_image

    def initialize(boat)
      boat_images = boat.boat_images.includes(:layout_image).to_a

      if boat_images.all?(&:regular?)
        @regular_images = boat_images
      else
        images_by_kind = boat_images.group_by(&:kind)
        @regular_images, layout_related_images = images_by_kind['regular']&.partition { |i| i.layout_image.nil? }
        layout_images_hash = images_by_kind['layout'].each_with_object({}) { |i, h| h[i] = nil }
        @images_by_layout_image = layout_images_hash.merge!(layout_related_images&.group_by(&:layout_image))
        @side_view_image = images_by_kind['side_view']&.first
      end
    end

  end
end
