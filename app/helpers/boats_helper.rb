module BoatsHelper
  def boat_length(boat, unit = nil)
    return '' if !boat.length_m || boat.length_m <= 0
    unit ||= current_length_unit || 'm'
    length = unit == 'ft' ? boat.length_ft.round : boat.length_m.round
    "#{length} #{unit}"
  end

  def boat_price(boat, target_currency = nil)
    if boat.poa?
      I18n.t('poa')
    else
      target_currency ||= current_currency || Currency.default
      price = Currency.convert(boat.price, boat.safe_currency, target_currency)
      number_to_currency(price, unit: target_currency.symbol, precision: 0)
    end
  end

  def boat_price_with_converted(boat)
    converted_price = boat_price(boat, current_currency)
    if boat.currency && boat.currency != current_currency
      "#{boat_price(boat, boat.currency)} (#{converted_price})"
    else
      converted_price
    end
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

  def boat_specs(boat, full_spec = false)
    ret = []
    ret << ['Seller', boat.user.name] if full_spec
    ret << ['Price', boat_price_with_converted(boat), 'price']
    ret << ['Year Built', boat.year_built]
    ret << ['Manufacturer', boat.manufacturer]
    ret << ['Model', boat.model]
    ret << ['Boat Type', boat.boat_type]
    ret << ['LOA', boat_length(boat), 'loa']
    ret << ['Location', boat.country.to_s]
    ret << ['Tax Status', boat.tax_status]
    ret << ['Engine Make', boat.engine_model]
    ret << ['Fuel', boat.fuel_type]

    if full_spec
      ret.concat boat.boat_specifications.visible_ordered_specs
    else
      ret.concat Specification.visible_ordered_boat_specs(boat)
    end

    ret << ['RB Ref', boat.ref_no]
    ret.map { |k, v| [k, v.presence || 'N/A'] }
  end

  def implicit_boats_count(count)
    count >= 10000 ? '10,000 plus' : count
  end
end