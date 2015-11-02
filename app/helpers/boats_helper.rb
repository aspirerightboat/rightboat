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
      price = Currency.convert(boat.price, boat.currency || Currency.default, target_currency)
      number_to_currency(price, unit: target_currency.symbol, precision: 0)
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

    if (length = boat.length_m)
      options = options.merge(
        length_min: length * 8 / 10,
        length_max: length * 12 / 10
      )
    end

    search_path(options)
  end

  def boat_specs(boat, full_spec = false)
    ret = []
    ret << ['Seller', boat.user.name] if full_spec
    ret << ['Price', boat_price(boat), 'price']
    ret << ['LOA', boat_length(boat), 'loa']
    ret << ['Manufacturer', boat.manufacturer]
    ret << ['Model', boat.model]
    ret << ['Boat Type', boat.boat_type]
    ret << ['Year Built', boat.year_built]
    ret << ['Location', boat.country.to_s]
    ret << ['Tax Status', boat.tax_status]
    ret << ['Engine make/model', boat.engine_model]
    ret << ['Fuel', boat.fuel_type]

    if full_spec
      ret.concat boat.boat_specifications.visible_ordered_specs
    else
      ret.concat Specification.visible_ordered_boat_specs(boat)
    end

    ret << ['RB Boat Ref', boat.ref_no]
    ret.map { |k, v| [k, v.presence || 'N/A'] }
  end
end