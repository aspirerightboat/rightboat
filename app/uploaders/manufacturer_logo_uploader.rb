class ManufacturerLogoUploader < ImageUploader

  def store_dir
    "manufacturer_logos/#{model.id}"
  end

  version :thumb do
    process :resize_and_pad => [300, 200]
  end
end
