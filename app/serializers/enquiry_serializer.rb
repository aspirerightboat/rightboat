class EnquirySerializer < ActiveModel::Serializer
  attributes :user_registered, :boat_pdf, :email, :broker

  has_many :similar_boats

  delegate :user_signed_in?, to: :scope

  def user_registered
    user_signed_in? || !!User.find_by_email(object.email)
  end

  def boat_pdf
    boat = object.boat
    boat_pdf_path(boat.slug)
  end

  def similar_boats
    Boat.similar_boats(object.boat)
  end

  def broker
    owner = object.boat.user
    {
      phone: owner.phone,
      name: owner.name
    }
  end

end