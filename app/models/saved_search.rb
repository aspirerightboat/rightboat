class SavedSearch < ActiveRecord::Base
  serialize :countries, Array
  serialize :states, Array
  serialize :models, Array
  serialize :manufacturers, Array
  serialize :tax_status, Hash
  serialize :new_used, Hash

  belongs_to :user, counter_cache: true

  def currency_sym
    Currency.cached_by_name(currency)&.symbol
  end

  def manufacturers_str
    Manufacturer.where(id: manufacturers).pluck(:name).join(', ') if manufacturers.present?
  end

  def models_str
    Model.where(id: models).pluck(:name).join(', ') if models.present?
  end

  def countries_str
    Country.where(id: countries).pluck(:name).join(', ') if countries.present?
  end

  def states_str
    if states.present?
      states_map = Rightboat::USStates.states_map
      states.map { |key| states_map[key] }.compact.join(', ')
    end
  end

  def to_search_params
    params = attributes.except('id', 'user_id', 'first_found_boat_id', 'created_at', 'alert', 'updated_at').symbolize_keys
    [:countries, :manufacturers, :models, :states].each do |attr|
      params[attr] = send(attr).join('-')
    end
    params
  end

  def to_succinct_search_hash
    result = to_search_params.select { |_, value| value.present? }
    result.delete(:currency) if result[:price_min].nil? && result[:price_max].nil?
    result.delete(:length_unit) if result[:length_min].nil? && result[:length_max].nil?
    result
  end

  def safe_assign_params(params)
    [:countries, :manufacturers, :models].each do |attr|
      self[attr] = (params[attr].to_s.split('-').select { |id| id =~ /\A\d+\z/ }.presence if params[attr].present?)
    end
    self.states = (params[:states].to_s.split('-').select { |id| id =~ /\A[A-Z]{2}\z/ }.presence if params[:states].present?)

    self.year_min = (params[:year_min].to_i.clamp(Rightboat::BoatSearch::YEARS_RANGE) if params[:year_min].present?)
    self.year_max = (params[:year_max].to_i.clamp(Rightboat::BoatSearch::YEARS_RANGE) if params[:year_max].present?)
    self.price_min = (params[:price_min].to_i.clamp(Rightboat::BoatSearch::PRICES_RANGE) if params[:price_min].present?)
    self.price_max = (params[:price_max].to_i.clamp(Rightboat::BoatSearch::PRICES_RANGE) if params[:price_max].present?)
    self.currency = (((Currency.cached_by_name(params[:currency])&.name if params[:currency].present?) || Currency.default.name) if price_min || price_max)
    self.length_unit = (params[:length_unit].presence_in(Boat::LENGTH_UNITS) || 'm' if params[:length_min].present? || params[:length_max].present?)
    length_range = length_unit == 'm' ? Rightboat::BoatSearch::M_LENGTHS_RANGE : Rightboat::BoatSearch::FT_LENGTHS_RANGE
    self.length_min = (params[:length_min].to_i.clamp(length_range) if params[:length_min].present?)
    self.length_max = (params[:length_max].to_i.clamp(length_range) if params[:length_max].present?)
    self.q = params[:q].presence
    self.boat_type = params[:boat_type].presence_in(%w(power sail))
    self.tax_status = (params[:tax_status].slice(:paid, :unpaid) if params[:tax_status].is_a?(Hash))
    self.new_used = (params[:new_used].slice(:new, :used) if params[:new_used].is_a?(Hash))

    search_params = to_search_params.merge!(order: 'created_at_desc')
    self.first_found_boat_id = Rightboat::BoatSearch.new.do_search(search_params, per_page: 1).hits.first&.primary_key

    # some params are from boats-for-sale page
    if params[:manufacturer].present? && (manufacturer = Manufacturer.find_by(name: params[:manufacturer]))
      self.manufacturers = [manufacturer.id.to_s]
    end
    if params[:country].present? && (country = Country.find_by(slug: params[:country]))
      self.countries = [country.id.to_s]
    end
  end

  def self.safe_create(user, params)
    ss = user.saved_searches.new
    ss.safe_assign_params(params)

    if !ss.same_exists?
      ss.save!
      ss.ensure_ss_alerts_enabled
      ss
    end
  end

  def same_exists?
    query = user.saved_searches.where(
        year_min: year_min,
        year_max: year_max,
        price_min: price_min,
        price_max: price_max,
        length_min: length_min,
        length_max: length_max,
        length_unit: length_unit,
        currency: currency,
        q: q,
        boat_type: boat_type,
    )
    [:tax_status, :new_used, :manufacturers, :models, :countries, :states].each do |attr|
      if (value = send(attr).presence)
        query = query.where("#{attr} = ?", value.to_yaml)
      else
        query = query.where("#{attr} IS NULL")
      end
    end

    query.exists?
  end

  def ensure_ss_alerts_enabled
    if !user.user_alert.saved_searches
      user.user_alert.update(saved_searches: true)
    end
  end

end
