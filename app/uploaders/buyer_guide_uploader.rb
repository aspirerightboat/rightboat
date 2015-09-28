class BuyerGuideUploader < ImageUploader

  version :thumb do
    process :resize_to_fill => [150, 150]
  end
end