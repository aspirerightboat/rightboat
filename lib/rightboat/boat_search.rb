module Rightboat
  class BoatSearch
    ORDER_TYPES = %w(score_desc created_at_desc price_desc price_asc year_asc year_desc length_m_desc length_m_asc)
    PER_PAGE = 30
    include ParamsReader

    attr_reader :facets_data, :search

    attr_reader :q, :manufacturer_model, :manufacturer_ids, :model_ids,
                :country_ids, :boat_type, :manufacturer_id, :model_id, :states,
                :year_min, :year_max, :price_min, :price_max, :length_min, :length_max, :country_id, :boat_type_id,
                :ref_no, :new_used, :tax_status, :page, :order, :order_col, :order_dir, :exclude_ref_no

    attr_reader :with_facets, :includes, :per_page

    def do_search(search_params, opts = {})
      read_params(search_params)

      @with_facets = opts[:with_facets]
      @includes = opts[:includes] || [:currency, :manufacturer, :model, :primary_image, :vat_rate, :country]
      @per_page = opts[:per_page] || PER_PAGE

      @search = Boat.retryable_solr_search!(include: includes) do
        if q
          exact_q_search_if_makemodel
          fulltext q do
            minimum_match 1
          end
        end
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

        any_of { manufacturer_ids.each { |manufacturer_id| with :manufacturer_id, manufacturer_id } } if manufacturer_ids
        any_of { model_ids.each { |model_id| with :model_id, model_id } } if model_ids

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

        any_of { states.each { |state| with :state, state } } if states

        any_of { country_ids.each { |country_id| with :country_id, country_id } } if country_ids
        # any_of { category.each { |category_id| with :category_id, category_id } } if category
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
      search = Boat.retryable_solr_search(retries: 1) do
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
        filtered_country_ids = country_facet_rows.map(&:value) + (country_ids.presence || [])
        countries_data = Country.where(id: filtered_country_ids).order(:name).pluck(:id, :name).map do |id, name|
          count = country_facet_rows.find { |x| x.value == id }.try(:count) || 0
          [id, name, count]
        end.sort_by(&:third).reverse.map do |id, name, count|
          count = count <= 1000 ? count.to_s : '1000+'
          [id, name, count]
        end
      else
        countries_data = Country.order(:name).pluck(:id, :name).map { |id, name| [id, name, nil] }
      end

      @facets_data = {
          price_min:  price_stats&.data && price_stats.min.try(:floor) || Boat::PRICES_RANGE.min,
          price_max:  price_stats&.data && price_stats.max.try(:ceil) || Boat::PRICES_RANGE.max,
          # year_min:   year_stats&.data && year_stats.min.try(:floor) || Boat::YEARS_RANGE.min,
          year_min:   boat_year_built_min || Boat::YEARS_RANGE.min,
          year_max:   year_stats&.data && year_stats.max.try(:ceil) || Boat::YEARS_RANGE.max,
          length_min: length_stats&.data && length_stats.min.try(:floor) || Boat::M_LENGTHS_RANGE.min,
          length_max: length_stats&.data && length_stats.max.try(:ceil) || Boat::M_LENGTHS_RANGE.max,
          countries_data: countries_data
      }
    end

    def read_params(params)
      @q = read_downcase_str(params[:q])
      @manufacturer_model = read_downcase_str(params[:manufacturer_model])
      @manufacturer_ids = read_ids(params[:manufacturers])
      @model_ids = read_ids(params[:models])
      @manufacturer_id = read_id(params[:manufacturer_id])
      @model_id = read_id(params[:model_id])
      @country_id = read_id(params[:country_id])
      @boat_type_id = read_id(params[:boat_type_id])
      @country_ids = read_ids(params[:countries])
      @boat_type = read_downcase_str(params[:boat_type])
      @year_min = read_boat_year(params[:year_min])
      @year_max = read_boat_year(params[:year_max])
      if (currency = read_currency(params[:currency]))
        @price_min = read_boat_price_gbp(params[:price_min], currency)
        @price_max = read_boat_price_gbp(params[:price_max], currency)
      end
      if (length_unit = read_length_unit(params[:length_unit]))
        @length_min = read_boat_length_m(params[:length_min], length_unit)
        @length_max = read_boat_length_m(params[:length_max], length_unit)
      end
      @ref_no = read_downcase_str(params[:ref_no])
      @new_used = read_new_used_hash(params[:new_used])
      @tax_status = read_tax_status_hash(params[:tax_status])
      @page = read_page(params[:page])
      if params[:order]
        @order_col, @order_dir = self.class.read_order(params[:order])
        @order = params[:order] if @order_col
      end
      @exclude_ref_no = read_downcase_str(params[:exclude_ref_no])
      @states = read_state_codes(params[:states])&.map(&:downcase)
    end

    def boat_year_built_min
      Rails.cache.fetch 'boat_year_built_min', expires_in: 1.day do
        Boat.where('year_built > 1000').order(year_built: :asc).first.year_built
      end
    end

    def exact_q_search_if_makemodel
      if !manufacturer_ids && !model_ids && is_makemodel_or_model_str(q)
        @q = %("#{q}")
      end
    end

    def is_makemodel_or_model_str(q)
      Boat.retryable_solr_search! {
        with :live, true
        paginate page: 1, per_page: 1
        any_of do
          with :manufacturer_model, q
          with :model, q
        end
      }.hits.any?
    end
    
  end
end
