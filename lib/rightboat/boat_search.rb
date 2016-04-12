module Rightboat
  class BoatSearch
    include Rightboat::SolrRetry

    ORDER_TYPES = %w(score_desc created_at_desc price_desc price_asc year_asc year_desc length_m_desc length_m_asc)
    YEARS_RANGE = (Date.today.year - 30)..Date.today.year
    PRICES_RANGE = 0..100_000_000
    LENGTHS_RANGE = 0..300
    PER_PAGE = 30

    attr_reader :facets_data, :search

    attr_reader :q, :manufacturer_model, :manufacturer, :model, :model_ids,
                :category, :country, :boat_type, :manufacturer_id, :model_id,
                :year_min, :year_max, :price_min, :price_max, :length_min, :length_max, :country_id, :boat_type_id,
                :ref_no, :new_used, :tax_status, :page, :order, :order_col, :order_dir, :exclude_ref_no

    attr_reader :with_facets, :includes, :per_page

    def do_search(search_params, opts = {})
      read_params(search_params)

      @with_facets = opts[:with_facets]
      @includes = opts[:includes] || [:currency, :manufacturer, :model, :primary_image, :vat_rate, :country]
      @per_page = opts[:per_page] || PER_PAGE

      @search = Boat.solr_search(include: includes) do
        fulltext q if q
        with :live, true
        with :ref_no, ref_no if ref_no
        without :ref_no, exclude_ref_no if exclude_ref_no
        paginate page: page, per_page: per_page
        order_by order_col, order_dir if order

        if new_used
          any_of do
            with :new_boat, true if new_used[:new]
            with :new_boat, false if new_used[:used]
          end
        end

        if tax_status
          any_of do
            with :tax_paid, true if tax_status[:paid]
            with :tax_paid, false if tax_status[:unpaid]
          end
        end

        if manufacturer_model
          any_of do
            with :manufacturer, manufacturer_model
            with :manufacturer_model, manufacturer_model
          end
        end

        with(:manufacturer, manufacturer) if manufacturer
        with(:model, model) if model
        with(:manufacturer_id, manufacturer_id) if manufacturer_id
        with(:model_id, model_id) if model_id
        with(:country_id, country_id) if country_id
        with(:boat_type_id, boat_type_id) if boat_type_id

        with(:price).greater_than_or_equal_to(price_min) if price_min
        with(:price).less_than_or_equal_to(price_max) if price_max

        with(:length_m).greater_than_or_equal_to(length_min) if length_min
        with(:length_m).less_than_or_equal_to(length_max) if length_max

        with(:year).greater_than_or_equal_to(year_min) if year_min
        with(:year).less_than_or_equal_to(year_max) if year_max

        any_of { country.each { |country_id| with :country_id, country_id } } if country
        any_of { category.each { |category_id| with :category_id, category_id } } if category
        any_of { model_ids.each { |model_id| with :model_id, model_id } } if model_ids
        with :boat_type, boat_type if boat_type

        if with_facets
          facet :country_id
          stats :year, :price, :length_m
        end
      end

      fetch_facets_data(@search) if with_facets

      self
    end

    def self.general_facets_cached
      Rails.cache.fetch 'general_search_facets', expires_in: 1.hour do
        BoatSearch.new.general_facets
      end
    end

    def general_facets
      search = solr_retry(1) do
        Boat.solr_search do
          with :live, true
          facet :country_id
          stats :year, :price, :length_m
          paginate page: 1, per_page: 0
        end
      end

      fetch_facets_data(search)
    end

    def results
      @search.results
    end

    def hits
      @search.hits
    end

    def self.read_order(target_order)
      if target_order.present? && ORDER_TYPES.include?(target_order)
        m = target_order.match(/\A(.*)_(asc|desc)\z/)
        [m[1].to_sym, m[2].to_sym]
      end
    end

    private

    def fetch_facets_data(search)
      price_stats = search&.stats(:price)
      year_stats = search&.stats(:year)
      length_stats = search&.stats(:length_m)

      if search
        country_facet_rows = search.facet(:country_id).rows
        filtered_country_ids = country_facet_rows.map(&:value) + (country.presence || [])
        countries_data = Country.where(id: filtered_country_ids).order(:name).pluck(:id, :name).map do |id, name|
          count = country_facet_rows.find { |x| x.value == id }.try(:count) || 0
          [id, name, count]
        end.sort_by(&:third).reverse
      else
        countries_data = Country.order(:name).pluck(:id, :name).map { |id, name| [id, name, nil] }
      end

      @facets_data = {
          price_min:  price_stats&.data&.min&.floor || PRICES_RANGE.min,
          price_max:  price_stats&.data&.max&.ceil || PRICES_RANGE.max,
          year_min:   year_stats&.data&.min&.floor || YEARS_RANGE.min,
          year_max:   year_stats&.data&.max&.ceil || YEARS_RANGE.max,
          length_min: length_stats&.data&.min&.floor || LENGTHS_RANGE.min,
          length_max: length_stats&.data&.max&.ceil || LENGTHS_RANGE.max,
          countries_data: countries_data
      }
    end

    def read_params(params)
      @q = read_str(params[:q])
      @manufacturer_model = read_tags(params[:manufacturer_model])
      @manufacturer = read_tags(params[:manufacturer])
      @model = read_tags(params[:model])
      @manufacturer_id = params[:manufacturer_id] if params[:manufacturer_id].present?
      @model_id = params[:model_id] if params[:model_id].present?
      @country_id = params[:country_id] if params[:country_id].present?
      @boat_type_id = params[:boat_type_id] if params[:boat_type_id].present?
      @category = read_tags(params[:category])
      @country = read_tags(params[:country])
      @model_ids = read_tags(params[:model_ids])
      @boat_type = read_str(params[:boat_type])
      @year_min = read_year(params[:year_min])
      @year_max = read_year(params[:year_max])
      @price_min = read_price(params[:price_min], params[:currency])
      @price_max = read_price(params[:price_max], params[:currency])
      @length_min = read_length(params[:length_min], params[:length_unit])
      @length_max = read_length(params[:length_max], params[:length_unit])
      @ref_no = read_str(params[:ref_no])
      @new_used = read_hash(params[:new_used], 'new', 'used')
      @tax_status = read_hash(params[:tax_status], 'paid', 'unpaid')
      @page = [params[:page].to_i, 1].max
      if params[:order]
        @order_col, @order_dir = self.class.read_order(params[:order])
        @order = params[:order] if @order_col
      end
      @exclude_ref_no = params[:exclude_ref_no]
    end

    def read_str(str)
      str.strip if str.present?
    end

    def read_tags(tags)
      if tags.present?
        tags.is_a?(Array) ? tags : tags.split(/\s*,\s*/).reject(&:blank?).presence
      end
    end

    def read_price(price, currency)
      if price.present?
        c = Currency.cached_by_name(currency) || Currency.default
        Currency.convert(price.to_i, c, Currency.default)
      end
    end

    def read_year(year)
      if year.present?
        year.to_i.clamp(1970, Time.current.year)
      end
    end

    def read_length(len, len_unit)
      if len.present?
        res = len.to_f
        res = res.ft_to_m if len_unit == 'ft'
        res.round(2).clamp(0, 1000)
      end
    end

    def read_hash(hash, *possible_keys)
      if hash.present? && hash.is_a?(Hash)
        hash.with_indifferent_access.slice(*possible_keys)
      end
    end
  end
end
