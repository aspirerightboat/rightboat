class ManufacturerLogoUploader < ImageUploader

  def store_dir
    "manufacturer_logos/#{model.id}"
  end

  version :thumb do
    process :resize_and_pad => [300, 200]
  end

  version :mini do
    process :resize_and_pad => [150, 100]
  end
end
