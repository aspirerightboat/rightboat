module Rightboat
  class BoatSearch
    ORDER_TYPES = %w(score created_at price_desc price_asc year_asc year_desc length_m_desc length_m_asc)
    YEARS_RANGE = 1970..Time.current.year
    PRICES_RANGE = 0..100_000_000
    LENGTHS_RANGE = 0..60

    attr_reader :facets_data, :search
    
    attr_reader :q, :manufacturer_model, :category, :country, :boat_type,
                :year_min, :year_max, :price_min, :price_max, :length_min, :length_max,
                :ref_no, :new_boat, :tax_paid, :page, :order_dir, :order, :exclude_id

    attr_reader :with_facets, :includes, :per_page

    def do_search(search_params, opts = {})
      prepare_params(search_params)

      @with_facets = opts[:with_facets]
      @includes = opts[:includes] || [:currency, :manufacturer, :model, :primary_image, :vat_rate, :country]
      @per_page = opts[:per_page] || 30

      @search = Boat.solr_search(include: includes) do
        fulltext q if q
        with :live, true
        with :ref_no, ref_no if ref_no
        without :id, exclude_id if exclude_id
        paginate page: page, per_page: per_page
        order_by order, order_dir if order

        with :new_boat, new_boat  if new_boat

        if !tax_paid.nil?
          with :tax_paid, true if tax_paid
          without :tax_paid, true if !tax_paid
        end

        if (manuf_model = manufacturer_model)
          any_of do
            with :manufacturer, manuf_model
            with :manufacturer_model, manuf_model
          end
        end

        with(:price).greater_than_or_equal_to(price_min) if price_min
        with(:price).less_than_or_equal_to(price_max) if price_max

        with(:length_m).greater_than_or_equal_to(length_min) if length_min
        with(:length_m).less_than_or_equal_to(length_max) if length_max

        with(:year).greater_than_or_equal_to(year_min) if year_min
        with(:year).less_than_or_equal_to(year_max) if year_max

        with :country_id, country if country
        with :category_id, category if category
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
      search = Boat.solr_search do
        with :live, true
        facet :country_id
        stats :year, :price, :length_m
        paginate page: 1, per_page: 0
      end

      fetch_facets_data(search)
    end

    def results
      @search.results
    end

    private

    def fetch_facets_data(search)
      price_stats = search.stats(:price)
      year_stats = search.stats(:year)
      length_stats = search.stats(:length_m)

      country_facet = search.facet(:country_id).rows
      countries_for_select = Country.where(id: country_facet.map(&:value)).order(:name).pluck(:id, :name).map do |id, name|
        ["#{name} (#{country_facet.find { |x| x.value == id }.count})", id]
      end

      @facets_data = {
          price_min:  (price_stats.min.try(:floor)) || PRICES_RANGE.min,
          price_max:  (price_stats.max.try(:ceil)) || PRICES_RANGE.max,
          year_min:   (year_stats.min.try(:floor)) || YEARS_RANGE.min,
          year_max:   (year_stats.min.try(:ceil)) || YEARS_RANGE.max,
          length_min: (length_stats.min.try(:floor)) || LENGTHS_RANGE.min,
          length_max: (length_stats.max.try(:ceil)) || LENGTHS_RANGE.max,
          countries_for_select: countries_for_select
      }
    end

    def prepare_params(params)
      @q = read_str(params[:q])
      @manufacturer_model = read_tags(params[:manufacturer_model])
      @category = read_tags(params[:category])
      @country = read_tags(params[:country])
      @boat_type = read_tags(params[:boat_type]).try(:first)
      @year_min = read_year(params[:year_min])
      @year_max = read_year(params[:year_max])
      @price_min = read_price(params[:price_min], params[:currency])
      @price_max = read_price(params[:price_max], params[:currency])
      @length_min = read_length(params[:length_min], params[:length_unit])
      @length_max = read_length(params[:length_max], params[:length_unit])
      @ref_no = read_str(params[:ref_no])
      @new_boat = read_hash_bool(params[:new_used], 'new', 'used')
      @tax_paid = read_hash_bool(params[:tax_status], 'paid', 'unpaid')
      @page = [params[:page].to_i, 1].max
      if params[:order].present? && ORDER_TYPES.include?(params[:order])
        @order_dir = params[:order].end_with?('_asc') ? :asc : :desc
        @order = params[:order].gsub(/_(?:asc|desc)\z/, '')
      end
      @exclude_id = params[:exclude_id]
    end

    def read_str(str)
      str.strip if str.present?
    end

    def read_tags(tags)
      if tags.present?
        tags.split(/\s*,\s*/).reject(&:blank?).presence
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

    def read_hash_bool(hash, true_key, false_key)
      if hash.present? && hash.is_a?(Hash)
        hash[true_key] ? true : (hash[false_key] ? false : nil)
      end
    end
  end
end
