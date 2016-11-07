module HomeHelper

  def fetch_featured_manufacturers
    @featured_manufacturers = Manufacturer.featured.logo_present.order(:name).limit(60).to_a
  end

  def fetch_featured_boats
    limit = 12
    country = Country.find_by(iso: session[:country])

    @featured_boats = Boat.featured.active.country_or_all(country).order('RAND()').limit(limit)
                          .includes(:manufacturer, :currency, :primary_image, :model, :vat_rate, :country, user: [:comment_request]).to_a

    limit -= @featured_boats.size

    if limit > 0
      other_boats = Boat.featured.active.limit(limit).order('RAND()')
                        .includes(:manufacturer, :currency, :primary_image, :model, :vat_rate, :country, user: [:comment_request])
      if session[:country] == 'US'
        other_boats = other_boats.where.not(country: country)
      else
        euro_country_ids = Country.european_country_ids.select { |x| x != country&.id }
        other_boats = other_boats.where(country_id: euro_country_ids)
      end
      @featured_boats.concat(other_boats.to_a)
    end

    @featured_boats, @featured_boats_slider = @featured_boats.partition.with_index { |_boat, i| i < 6 }
  end

  def fetch_newest_boats
    @newest_boats = Boat.active.order('id DESC').limit(15).includes(:currency, :manufacturer, :model, :country)
  end

  def fetch_recent_viewed_boats
    boat_ids = nil

    if current_user
      boat_ids = current_user.user_activities.where(kind: 'boat_view')
                     .order('id DESC').group(:boat_id).limit(3).pluck(:boat_id)
      if boat_ids.empty? && cookies[:recently_viewed_boat_ids]
        boat_ids = Boat.where(id: cookies.delete(:recently_viewed_boat_ids).split(',')).limit(3).pluck(:id)
        boat_ids.each { |boat_id| UserActivity.create_boat_visit(boat_id: boat_id, user: current_user) }
      end
    elsif cookies[:recently_viewed_boat_ids]
      boat_ids = cookies[:recently_viewed_boat_ids].split(',')
    end

    if boat_ids&.any?
      @recent_boats = Boat.active.where(id: boat_ids)
                          .includes(:currency, :manufacturer, :model, :country, :primary_image).to_a
    end
  end

end
