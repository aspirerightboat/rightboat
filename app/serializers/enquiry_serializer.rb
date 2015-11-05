class EnquirySerializer < ActiveModel::Serializer
  attributes :user_registered, :boat_pdf, :email, :broker, :similar_link

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
    Rightboat::BoatSearch.new(object.boat.similar_options).retrieve_boats
  end

  def similar_link
    search_path(object.boat.similar_options)
  end

  def broker
    owner = object.boat.user
    {
      phone: owner.phone,
      name: owner.name
    }
  end

end