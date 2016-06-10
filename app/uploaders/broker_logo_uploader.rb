class BrokerLogoUploader < ImageUploader

  def store_dir
    "broker_logos/#{model.id}"
  end

  version :thumb do
    process :resize_and_pad => [400, 200]
  end
end