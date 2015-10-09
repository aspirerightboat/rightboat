class BrokerLogoUploader < ImageUploader

  def store_dir
    "rb-assets/broker-logos/#{model.id}"
  end

  version :thumb do
    process :resize_to_fill => [400, 200]
  end
end