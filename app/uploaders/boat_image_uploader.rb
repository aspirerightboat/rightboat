class BoatImageUploader < ImageUploader

  process :store_dimensions

  def store_dir
    i = model.id
    "boat_images/#{i / 1000_000}/#{i / 1000}/#{i}" # generally it is a good idea to not have so many files in one folder
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
      model.width, model.height = `identify -format "%w %h" #{file.path}`.split(' ')
    end
  end
end