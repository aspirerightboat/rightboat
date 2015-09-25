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

    link_to 'Favourite', '#', class: fav_class, title: fav_title, data: {toggle: 'tooltip', placement: 'top'}
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
end