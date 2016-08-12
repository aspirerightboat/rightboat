module HomeHelper

  def fetch_featured_boats
    country = Country.find_by(iso: session[:country])

    @featured_boats = Boat.featured.active.country_or_all(country).order('RAND()').limit(12)
                          .includes(:manufacturer, :currency, :primary_image, :model, :vat_rate, :user, :country).to_a

    length = @featured_boats.length

    if length < 6
      limit = 6 - length

      other_boats = Boat.featured.active.limit(limit).order('RAND()')
                        .includes(:manufacturer, :currency, :primary_image, :model, :vat_rate, :user, :country)
      if session[:country] == 'US'
        other_boats = other_boats.where.not(country: country)
      else
        euro_country_ids = Country.european_country_ids.select { |x| x != country&.id }
        other_boats = other_boats.where(country_id: euro_country_ids)
      end
      @featured_boats += other_boats.to_a
    end
  end

  def fetch_newest_boats
    @newest_boats = Boat.active.order('id DESC').limit(21).includes(:currency, :manufacturer, :model, :country)
  end

end
