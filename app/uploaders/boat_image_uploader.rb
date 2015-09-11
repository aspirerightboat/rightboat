class BoatImageUploader < ImageUploader
  def store_dir
    "rb-assets/boat-images/#{model.id}"
  end

  version :main do
    process :resize_to_limit => [1280, 534]
  end

  version :thumb do
    process :resize_to_limit => [350, 146]
  end

  version :mini do
    process :resize_to_limit => [127, 42]
  end
end