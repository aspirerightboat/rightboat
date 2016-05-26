class SavedSearch < ActiveRecord::Base

  include ActionView::Helpers::NumberHelper

  serialize :countries, Array
  serialize :models, Array
  serialize :manufacturers, Array
  serialize :tax_status, Hash
  serialize :new_used, Hash

  belongs_to :user, counter_cache: true

  def currency_sym
    Currency.cached_by_name(currency).try(:symbol)
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

  def search_title
    not_defined = '..'
    res = ''
    res << %( Keyword = "#{q}") if q.present?
    res << %( BoatType = "#{boat_type}") if boat_type.present?
    res << %( Manufacturers = "#{manufacturers_str}") if manufacturers_str.present?
    res << %( Models = "#{models_str}") if models_str.present?
    res << %( Countries = "#{countries_str}") if countries_str.present?
    res << %( Year = #{year_min.presence || not_defined} - #{year_max.presence || not_defined}) if year_min.present? || year_max.present?
    res << %( Price = #{currency_sym} #{number_with_delimiter(price_min.presence) || 0} - #{number_with_delimiter(price_max.presence) || not_defined}) if price_min.present? || price_max.present?
    res << %( Length = #{length_min.presence || not_defined} - #{length_max.presence || not_defined}#{length_unit}) if length_min.present? || length_max.present?
    res << %( RefNo = "#{ref_no}") if ref_no.present?
    res.strip!
    res
  end

  def to_search_params
    attributes.except('id', 'user_id', 'first_found_boat_id', 'created_at', 'alert', 'updated_at').symbolize_keys
  end

  def to_succinct_search_hash
    to_search_params.select { |_, value| value.present? }
  end

  def self.create_and_run(user, params)
    fixed_params = {
        year_min: params[:year_min].presence,
        year_max: params[:year_max].presence,
        price_min: params[:price_min].presence,
        price_max: params[:price_max].presence,
        length_min: params[:length_min].presence,
        length_max: params[:length_max].presence,
        length_unit: params[:length_unit].presence,
        currency: params[:currency].presence,
        ref_no: params[:ref_no].to_s,
        q: params[:q].to_s,
        boat_type: params[:boat_type].presence,
        order: params[:order].to_s,
    }

    query = user.saved_searches.where(fixed_params)

    [:tax_status, :new_used, :manufacturers, :models, :countries].each do |p|
      if params[p].blank?
        query = query.where("#{p} IS NULL")
      else
        fixed_params[p] = params[p]
        query = query.where("#{p} = ?", params[p].to_yaml)
      end
    end

    if !query.exists?
      ss = user.saved_searches.new(fixed_params)
      ss.first_found_boat_id = Rightboat::BoatSearch.new.do_search(params, per_page: 1).hits.first.try(:primary_key)
      ss.save!
      ss
    end
  end
end
