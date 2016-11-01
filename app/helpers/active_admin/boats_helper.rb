module ActiveAdmin::BoatsHelper
  def boat_admin_price(boat)
    return I18n.t('poa') if boat.poa?
    number_to_currency(boat.price, unit: boat.safe_currency.symbol, precision: 0)
  end

  def boat_length_with_hint(boat)
    if boat.length_m
      content_tag :abbr, "#{boat.length_m}m", title: "#{boat.length_ft}ft"
    end
  end

  def boat_link(boat)
    link_to boat.manufacturer_model, makemodel_boat_path(boat)
  end

  def boat_location_column(boat)
    [boat.location, boat.country&.name].reject(&:blank?).join('<br>').html_safe
  end
end
