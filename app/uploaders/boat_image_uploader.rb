class BoatImageUploader < ImageUploader
  def store_dir
    "rb-assets/boat-images/#{model.id}"
  end

  version :main do
    process :resize_to_limit => [1280, 534]
  end

  version :thumb do
    process :resize_to_fill => [350, 234]
  end

  version :mini do
    process :resize_to_fill => [127, 101]
  end
end