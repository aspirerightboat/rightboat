class BrokerLogoUploader < ImageUploader

  def store_dir
    "broker_logos/#{model.id}"
  end

  version :thumb do
    process :resize_to_fill => [400, 200]
  end
end