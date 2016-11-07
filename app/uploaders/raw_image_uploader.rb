class RawImageUploader < ImageUploader

  def store_dir
    "images/misc/#{model.id}"
  end

  version :thumb do
    process :resize_to_fill => [50, 50]
  end
end
