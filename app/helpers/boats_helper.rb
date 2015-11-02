module BoatsHelper
  def boat_length(boat, unit = current_length_unit)
    boat.display_length(unit)
  end

  def boat_price(boat, currency = current_currency)
    boat.display_price(currency)
  end

  def favourite_link_to(boat)
    favourited = boat.favourited_by?(current_user)
    fav_class = favourited ? 'fav-link active' : 'fav-link'
    fav_title = favourited ? 'Unfavourite' : 'Favourite'

    link_to 'Favourite', "#favourite-#{boat.id}", id: "favourite-#{boat.id}", class: fav_class, title: fav_title, data: {toggle: 'tooltip', placement: 'top'}
  end

  def reduced_description(description=nil)
    return '' if description.blank?
    length = vlength = 0
    description = description.gsub(/(^<p>|<\/p>$)/, '').gsub('&lt;br /&gt;', ' ')
    description.split('.').each do |x|
      breaker = x[/<(br\s+\/|h\d|p)>/]
      vlength += 50 if breaker
      break if (vlength + x.length) > 410
      vlength += (x.length + 1)
      length += (x.length + (breaker ? breaker.length : 1))
    end

    sanitize(description[0..(length - 1)])
  end

  def similar_link(boat)
    currency = current_currency || Currency.default
    price = Currency.convert(boat.price, boat.currency, currency)
    options = {
      exclude: boat.ref_no,
      currency: currency.name,
      price_min: (price * 8 / 10).to_i,
      price_max: (price * 12 / 10).to_i,
      boat_type: [boat.boat_type.try(&:name_stripped)],
      category: [boat.category_id]
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