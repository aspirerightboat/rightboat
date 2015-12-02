class EnquirySerializer < ActiveModel::Serializer
  attributes :just_logged_in, :boat_pdf, :email, :broker, :similar_link

  has_many :similar_boats

  def boat_pdf
    boat_pdf_path(object.boat)
  end

  def similar_boats
    Rightboat::BoatSearch.new.do_search(object.boat.similar_options).results
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