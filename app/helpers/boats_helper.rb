module BoatsHelper
  def boat_title(boat)
    "#{boat.manufacturer_model} for sale"
  end

  def boat_length(boat, unit = nil)
    return '' if !boat.length_m || boat.length_m <= 0
    unit ||= try(:current_length_unit) || 'm'
    length = unit == 'ft' ? boat.length_ft.round : boat.length_m.round
    "#{length} #{unit}"
  end

  def converted_size(size, unit = nil)
    return nil if !size
    size = size.to_f
    return nil if size <= 0
    unit ||= try(:current_length_unit) || 'm'
    size = unit == 'ft' ? size.m_to_ft.round : size
    "#{size} #{unit}"
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

    link_to 'Favourite', "#favourite-#{boat.id}", id: "favourite-#{boat.id}", class: fav_class, title: fav_title, data: {'boat-id' => boat.id, toggle: 'tooltip', placement: 'top'}
  end

  def boat_specs(boat, full_spec = false)
    spec_names = %w(beam_m draft_m draft_max draft_min drive_up engine_count berths_count cabins_count hull_material engine keel keel_type)
    spec_value_by_name = boat.boat_specifications.not_deleted.custom_specs_hash(spec_names)

    ret = []
    ret[0] = []
    ret[0] << ['Make', link_to(boat.manufacturer.name, sale_manufacturer_path(manufacturer: boat.manufacturer))]
    ret[0] << ['Model', link_to(boat.model.name, sale_manufacturer_path(manufacturer: boat.manufacturer, models: boat.model.id))]
    ret[0] << ['LOA', boat_length(boat), 'loa']
    ret[0] << ['Beam', converted_size(spec_value_by_name['beam_m'])]
    if spec_value_by_name['draft_max']
      ret[0] << ['Draft Max', converted_size(spec_value_by_name['draft_max'])]
    else
      ret[0] << ['Draft Max', converted_size(spec_value_by_name['draft_m'])]
    end
    if spec_value_by_name['draft_min']
      ret[0] << ['Draft Min', converted_size(spec_value_by_name['draft_min'])]
    elsif spec_value_by_name['drive_up']
      ret[0] << ['Draft Min', converted_size(spec_value_by_name['drive_up'])]
    end
    ret[0] << ['Keel', spec_value_by_name['keel'] || spec_value_by_name['keel_type']]
    ret[0] << ['Hull Material', spec_value_by_name['hull_material']]
    ret[0] << ['Boat Type', boat.boat_type]
    ret[0] << ['RB Ref', boat.ref_no]

    ret[1] = []
    ret[1] << ['Price', boat_price_with_converted(boat), 'price']
    ret[1] << ['Tax Status', boat.tax_status]
    ret[1] << ['Year', boat.year_built]
    ret[1] << ['Engine Make', boat.engine_manufacturer.try(:name) || spec_value_by_name['engine']]
    ret[1] << ['Engine Model', boat.engine_model.try(:name)]
    ret[1] << ['Engine Count', spec_value_by_name['engine_count']]
    ret[1] << ['Fuel', boat.fuel_type.try(:name)]
    ret[1] << ['Cabins', spec_value_by_name['cabins_count']]
    ret[1] << ['Berths', spec_value_by_name['berths_count']]
    ret[1] << ['Location', boat.location]

    if boat.country
      ret[1] << ['Country', link_to(boat.country.name, sale_manufacturer_path(manufacturer: boat.manufacturer,
                                                                            models: boat.model.id,
                                                                            country: boat.country.slug))]
    end

    # rest = if full_spec
    #          boat.boat_specifications.visible_ordered_specs
    #        else
    #          Specification.visible_ordered_boat_specs(boat)
    #        end

    # rest.each do |pair|
    #   ret << pair if ret.none? { |k, v| k == pair[0] }
    # end

    ret.each { |col| col.select! { |pair| !pair[1].blank? } }
  end

  def implicit_boats_count(count)
    count >= 10000 ? '10,000 plus' : count
  end

  def boats_index_filters_data
    @top_manufacturer_infos = Manufacturer.joins(:boats).where(boats: {status: 'active'})
                                  .group('manufacturers.name, manufacturers.slug')
                                  .order('COUNT(*) DESC').limit(60)
                                  .pluck('manufacturers.name, manufacturers.slug, COUNT(*)').sort_by!(&:first)

    @boat_types = BoatType.joins(:boats).where(boats: {status: 'active'})
                      .group('boat_types.name, boat_types.slug')
                      .order('boat_types.name')
                      .select('boat_types.name, boat_types.slug, COUNT(*) AS boats_count')

    @countries = Country.joins(:boats).where(boats: {status: 'active'})
                     .group('countries.name, countries.slug')
                     .order('countries.name')
                     .select('countries.name, countries.slug, COUNT(*) AS boats_count')
  end
end
