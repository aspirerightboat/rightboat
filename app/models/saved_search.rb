class SavedSearch < ActiveRecord::Base

  include ActionView::Helpers::NumberHelper

  serialize :country, Array
  serialize :category, Array
  serialize :models, Array
  serialize :tax_status, Hash
  serialize :new_used, Hash

  belongs_to :user, counter_cache: true

  def search_title
    not_defined = '..'
    currency_sym = Currency.cached_by_name(currency).try(:symbol)
    res = ''
    res << %( Keyword = "#{q}") if q.present?
    res << %( BoatType = "#{boat_type}") if boat_type.present?
    res << %( Manufacturer = "#{manufacturer}") if manufacturer.present?
    res << %( Model = "#{model}") if model.present?
    res << %( Country = "#{country}") if country.present?
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
        manufacturer: params[:manufacturer].to_s,
        model: params[:model].to_s,
    }

    query = user.saved_searches.where(fixed_params)

    [:tax_status, :new_used, :country, :models].each do |p|
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
    end
  end
end
