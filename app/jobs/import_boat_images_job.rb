class ImportBoatImagesJob
  def initialize(import_trail_id, boat_id, images_info, proxy_url)
    @import_trail_id = import_trail_id
    @boat_id = boat_id
    @images_info = images_info
    @proxy_url = proxy_url
  end

  def perform
    boat = Boat.find(@boat_id)
    boat_image_by_url = boat.boat_images.index_by(&:source_url)
    images_count = 0

    import_trail = ImportTrail.find(@import_trail_id)
    logger = nil
    log_error_proc = ->(msg) {
      logger ||= Logger.new(import_trail.log_path)
      logger.error(msg)
    }

    @images_info.each do |item| # items possible keys: :url, :caption, :mod_time
      url = item[:url]
      url.strip!
      img = boat_image_by_url.delete(url) || BoatImage.new(source_url: url, boat: boat)

      if (caption = item[:caption])
        caption = caption[0..254] + '…' if caption.size > 255
        img.caption = caption
      end

      mod_time = item[:mod_time]
      if img.new_record? || !mod_time || mod_time > img.downloaded_at
        img.update_image_from_source(proxy_url: @proxy_url, log_error_proc: log_error_proc)
      end

      success = !img.changed? || img.file_exists? && img.save
      images_count += 1 if success
    end

    if images_count > 0
      ImportTrail.where(id: @import_trail_id).update_all(['images_count = images_count + ?', images_count])
    end

    if boat_image_by_url.any?
      boat_image_by_url.each { |_url, img| img.destroy }
    end
  end
end
