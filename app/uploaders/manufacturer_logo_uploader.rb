class ManufacturerLogoUploader < ImageUploader
  version :thumb do
    process :resize_and_pad => [300, 200]
  end
end
