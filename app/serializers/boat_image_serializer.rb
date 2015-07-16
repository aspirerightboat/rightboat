class BoatImageSerializer < ActiveModel::Serializer
  attributes :thumb, :main, :mini, :origin

  def thumb
    object.file_url(:thumb)
  end

  def mini
    object.file_url(:mini)
  end

  def main
    object.file_url(:main)
  end

  def origin
    object.file_url
  end
end