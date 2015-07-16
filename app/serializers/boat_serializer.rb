class BoatSerializer < ActiveModel::Serializer

  attributes :slug, :manufacturer, :model
  has_one :primary_image

  def manufacturer
    object.manufacturer.to_s
  end

  def model
    object.model.to_s
  end
end