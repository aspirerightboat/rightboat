class BoatImageSerializer < ActiveModel::Serializer
  attributes :thumb, :mini, :origin

  def thumb
    object.file_url(:thumb)
  end

  def mini
    object.file_url(:mini)
  end

  def origin
    object.file_url
  end
end