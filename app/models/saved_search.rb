class SavedSearch < ActiveRecord::Base
  serialize :countries, Array
  serialize :states, Array
  serialize :models, Array
  serialize :manufacturers, Array
  serialize :tax_status, Hash
  serialize :new_used, Hash

  include Rightboat::ParamsReader

  belongs_to :user, counter_cache: true

  def currency_sym
    Currency.cached_by_name(currency)&.symbol
  end

  def manufacturers_str
    Manufacturer.where(id: manufacturers).order(:name).pluck(:name).join(', ') if manufacturers.present?
  end

  def models_str
    Model.where(id: models).order(:name).pluck(:name).join(', ') if models.present?
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
    sp = Rightboat::SearchParams.new(params).read

    self.countries = sp.country_ids
    self.manufacturers = sp.manufacturer_ids
    self.models = sp.model_ids
    self.states = read_ids(params[:states])
    self.year_min = sp.year_min
    self.year_max = sp.year_max
    self.price_min = sp.price_min
    self.price_max = sp.price_max
    self.currency = sp.currency&.name
    self.length_min = sp.length_min
    self.length_max = sp.length_max
    self.length_unit = sp.length_unit
    self.q = sp.q
    self.boat_type = sp.boat_type
    self.tax_status = sp.tax_status
    self.new_used = sp.new_used

    fixed_params = to_search_params.merge!(order: 'created_at_desc', per_page: 1)
    self.first_found_boat_id = Rightboat::BoatSearch.new.do_search(params: fixed_params).hits.first&.primary_key
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
