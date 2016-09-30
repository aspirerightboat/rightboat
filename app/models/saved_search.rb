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
    self.countries = read_ids(params[:countries])
    self.manufacturers = read_ids(params[:manufacturers])
    self.models = read_ids(params[:models])
    self.states = read_ids(params[:states])
    self.year_min = read_boat_year(params[:year_min])
    self.year_max = read_boat_year(params[:year_max])
    if (currency = read_currency(params[:currency]))
      self.price_min = read_boat_price(params[:price_min])
      self.price_max = read_boat_price(params[:price_max])
      self.currency = (currency.name if price_min || price_max)
    end
    if (length_unit = read_length_unit(params[:length_unit]))
      self.length_min = read_boat_length(params[:length_min], length_unit)
      self.length_max = read_boat_length(params[:length_max], length_unit)
      self.length_unit = (length_unit if length_min || length_max)
    end
    self.q = read_str(params[:q])
    self.boat_type = params[:boat_type].presence_in(%w(power sail))
    self.tax_status = read_tax_status_hash(params[:tax_status])
    self.new_used = read_new_used_hash(params[:new_used])

    search_params = to_search_params.merge!(order: 'created_at_desc')
    self.first_found_boat_id = Rightboat::BoatSearch.new.do_search(search_params, per_page: 1).hits.first&.primary_key

    # some params are from boats-for-sale page
    if params[:manufacturer].present? && (manufacturer = Manufacturer.find_by(name: params[:manufacturer]))
      self.manufacturers = [manufacturer.id]
    end
    if params[:country].present? && (country = Country.find_by(slug: params[:country]))
      self.countries = [country.id]
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
