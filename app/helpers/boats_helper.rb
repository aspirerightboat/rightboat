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

    link_to 'Favourite', "#favourite-#{boat.id}", id: "favourite-#{boat.id}", class: fav_class, title: fav_title, data: {toggle: 'tooltip', placement: 'top'}
  end

  def boat_specs(boat, full_spec = false)
    spec_names = %w(beam_m draft_m engine_horse_power engine_count berths_count cabins_count hull_material engine)
    spec_value_by_name = boat.boat_specifications.custom_specs_hash(spec_names)

    ret = []
    #ret << ['Seller', boat.user.name] if full_spec
    ret << ['Price', boat_price_with_converted(boat), 'price']
    ret << ['Year', boat.year_built]
    ret << ['Make', link_to(boat.manufacturer.name, sale_manufacturer_path(manufacturer: boat.manufacturer))]
    ret << ['Model', link_to(boat.model.name, sale_manufacturer_path(manufacturer: boat.manufacturer, models: boat.model.id))]
    ret << ['Boat Type', boat.boat_type]
    ret << ['LOA', boat_length(boat), 'loa']
    ret << ['Beam', converted_size(spec_value_by_name['beam_m'])]
    ret << ['Draft', converted_size(spec_value_by_name['draft_m'])]
    ret << ['Engine Make', boat.engine_manufacturer.try(:name) || spec_value_by_name['engine']]
    ret << ['HP', spec_value_by_name['engine_horse_power']]
    ret << ['Engine Count', spec_value_by_name['engine_count']]
    ret << ['Fuel', boat.fuel_type.try(:name)]
    ret << ['Berths', spec_value_by_name['berths_count']]
    ret << ['Cabins', spec_value_by_name['cabins_count']]
    ret << ['Location', link_to_if(boat.country, boat.country.name, sale_manufacturer_path(manufacturer: boat.manufacturer,
                                                                                           models: boat.model.id,
                                                                                           country: boat.country.slug))]
    ret << ['Tax Status', boat.tax_status]
    ret << ['RB Ref', boat.ref_no]
    ret << ['Hull Material', spec_value_by_name['hull_material']]

    rest = if full_spec
             boat.boat_specifications.visible_ordered_specs
           else
             Specification.visible_ordered_boat_specs(boat)
           end

    rest.each do |pair|
      ret << pair if ret.none? { |k, v| k == pair[0] }
    end

    #ret.each { |pair| pair[1] = 'N/A' if pair[1].blank? }
    ret.select { |pair| !pair[1].blank? }
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
