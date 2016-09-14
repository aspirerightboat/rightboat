module SavedSearchHelper
  def saved_search_title(ss)
    not_defined = '..'
    res = String.new
    if ss.q.present?
      res << %( Keyword:&nbsp;<b>#{h ss.q}</b>;)
    end
    if ss.boat_type.present?
      res << %( BoatType:&nbsp;<b>#{h ss.boat_type&.titleize}</b>;)
    end
    if (manufacturers_str = ss.manufacturers_str)
      res << %( Manufacturers:&nbsp;<b>#{h manufacturers_str}</b>;) if manufacturers_str.present?
    end
    if (models_str = ss.models_str)
      res << %( Models:&nbsp;<b>#{h models_str}</b>;) if models_str.present?
    end
    if (countries_str = ss.countries_str)
      res << %( Countries:&nbsp;<b>#{h countries_str}</b>;) if countries_str.present?
    end
    if (states_str = ss.states_str)
      res << %( States:&nbsp;<b>#{h states_str}</b>;) if states_str.present?
    end
    if ss.year_min.present? || ss.year_max.present?
      year_from = ss.year_min.presence || not_defined
      year_to = ss.year_max.presence || not_defined
      res << %( Year:&nbsp;<b>#{h year_from}&nbsp;-&nbsp;#{h year_to}</b>;)
    end
    if ss.price_min.present? || ss.price_max.present?
      price_from = number_with_delimiter(ss.price_min.presence) || 0
      price_to = number_with_delimiter(ss.price_max.presence) || not_defined
      res << %( Price:&nbsp;<b>#{h ss.currency_sym}#{h price_from}&nbsp;-&nbsp;#{h price_to}</b>;)
    end
    if ss.length_min.present? || ss.length_max.present?
      length_from = ss.length_min.presence&.to_i || not_defined
      length_to = ss.length_max.presence&.to_i || not_defined
      res << %( Length:&nbsp;<b>#{h length_from}&nbsp;-&nbsp;#{h length_to}#{h ss.length_unit}</b>;)
    end
    if ss.ref_no.present?
      res << %( RefNo:&nbsp;<b>#{h ss.ref_no}</b>;)
    end
    if ss.tax_status.present?
      res << %( Tax Status:&nbsp;<b>#{h ss.tax_status.keys.map { |k| k.titleize }.join(', ')}</b>;)
    end
    if ss.new_used.present?
      res << %( New/Used:&nbsp;<b>#{h ss.new_used.keys.map { |k| k.titleize }.join(', ')}</b>;)
    end
    res.strip!
    res.gsub!(/;\z/, '')
    res.html_safe
  end
end
