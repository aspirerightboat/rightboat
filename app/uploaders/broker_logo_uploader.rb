class BrokerLogoUploader < ImageUploader

  process :store_dimensions

  def store_dir
    "rb-assets/broker-logos/#{model.id}"
  end

  private

  def store_dimensions
  end
end