class BoatImageUploader < ImageUploader

  process :store_dimensions

  def store_dir
    "rb-assets/boat-images/#{model.id}"
  end

  version :thumb do
    process :resize_to_fill => [427, 285]
  end

  version :mini do
    process :resize_to_fill => [127, 85]
  end

  private

  def store_dimensions
    if file && model
      img = ::Magick::Image::read(file.file).first
      model.width = img.columns
      model.height = img.rows
    end
  end
end