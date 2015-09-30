module BoatsHelper
  def boat_length(boat, unit = current_length_unit)
    boat.display_length(unit)
  end

  def boat_price(boat, currency = current_currency)
    boat.display_price(currency)
  end

  def fav_class(boat = @boat)
    return 'fav-link' unless user_signed_in?

    boat.booked_by?(current_user) ? 'fav-link active' : 'fav-link'
  end

  def fav_label(boat)
    return 'Favourite' unless user_signed_in?
    boat.booked_by?(current_user) ? "Favourited on #{boat.favourited_at_by(current_user)}" : 'Favourite'
  end

  def fav_title(boat)
    boat.booked_by?(current_user) ? 'Unfavourite' : 'Favourite'
  end

  def favourite_link_to(boat, label = nil)
    link_to label || fav_label(boat), '#', class: fav_class(boat), title: fav_title(boat), data: { toggle: 'tooltip', placement: 'top' }
  end

  def reduced_description(description=nil)
    return '' if description.blank?
    length = vlength = 0
    description.split('.').each do |x|
      vlength += 50 if x =~ /<(br|h\d|p)>/
      break if (vlength + x.length) > 410
      vlength += (x.length + 1)
      length += (x.length + 1)
    end

    sanitize(description[0..(length - 1)])
  end

  def similar_link(boat)
    options = {
      currency: boat.currency.name,
      price_min: boat.price * 8 / 10,
      price_max: boat.price * 12 / 10
    }

    if length = boat.length_m
      options = options.merge(
        length_min: length * 8 / 10,
        length_max: length * 12 / 10
      )
    end

    search_path(options)
  end
end