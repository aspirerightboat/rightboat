module Rightboat
  class SearchParams
    ORDER_TYPES = %w(score_desc created_at_desc price_desc price_asc year_asc year_desc length_m_desc length_m_asc)
    include ParamsReader
    attr_reader :q, :manufacturer_model, :manufacturer, :manufacturer_id, :manufacturer_ids,
                :model_id, :model_ids, :country, :country_id, :country_ids, :states,
                :year_min, :year_max, :price_min, :price_max, :length_min, :length_max,
                :boat_type, :boat_type_id, :new_used, :tax_status, :ref_no, :exclude_ref_no,
                :page, :order, :order_col, :order_dir, :currency, :length_unit

    def initialize(params)
      @params = params
    end

    def read
      @q = read_downcase_str(@params[:q])
      @manufacturer_model = read_downcase_str(@params[:manufacturer_model])
      @manufacturer_ids = read_ids(@params[:manufacturers])
      @model_ids = read_ids(@params[:models])
      @manufacturer = read_manufacturer(@params[:manufacturer])
      @manufacturer_id = read_id(@params[:manufacturer_id])
      @model_id = read_id(@params[:model_id])
      @country_id = read_id(@params[:country_id])
      @country = read_country(@params[:country])
      @country_ids = read_ids(@params[:countries])
      @boat_type_id = read_id(@params[:boat_type_id])
      @boat_type = read_boat_type(@params[:boat_type])
      @year_min = read_boat_year(@params[:year_min])
      @year_max = read_boat_year(@params[:year_max])
      if (@currency = read_currency(@params[:currency]))
        @price_min = read_boat_price(@params[:price_min])
        @price_max = read_boat_price(@params[:price_max])
      end
      if (@length_unit = read_length_unit(@params[:length_unit]))
        @length_min = read_boat_length(@params[:length_min], @length_unit)
        @length_max = read_boat_length(@params[:length_max], @length_unit)
      end
      @ref_no = read_downcase_str(@params[:ref_no])
      @new_used = read_new_used_hash(@params[:new_used])
      @tax_status = read_tax_status_hash(@params[:tax_status])
      @page = read_page(@params[:page])
      if @params[:order]
        @order_col, @order_dir = read_search_order(@params[:order])
        @order = @params[:order] if @order_col
      end
      @exclude_ref_no = read_downcase_str(@params[:exclude_ref_no])
      @states = read_state_codes(@params[:states])
      normalize_params
      self
    end

    def downcase_states
      states&.map(&:downcase)
    end

    def length_m_min
      Rightboat::Unit.convert_length(length_min, length_unit, 'm')
    end

    def length_m_max
      Rightboat::Unit.convert_length(length_max, length_unit, 'm')
    end

    def price_gbp_min
      Currency.convert(price_min, currency, Currency.default)
    end

    def price_gbp_max
      Currency.convert(price_max, currency, Currency.default)
    end

    def to_h
      h = {}
      try_add_key = ->(attr) { value = send(attr); h[attr] = value if value }
      try_add_key.(:q)
      try_add_key.(:manufacturer_model)
      unless try_add_key.(:manufacturer_ids)
        unless try_add_key.(:manufacturer)
          try_add_key.(:manufacturer_id)
        end
      end
      unless try_add_key.(:model_ids)
        try_add_key.(:model_id)
      end
      unless try_add_key.(:country_ids)
        unless try_add_key.(:country)
          try_add_key.(:country_id)
        end
      end
      unless try_add_key.(:boat_type)
        try_add_key.(:boat_type_id)
      end
      try_add_key.(:states)
      try_add_key.(:year_min)
      try_add_key.(:year_max)
      try_add_key.(:price_min)
      try_add_key.(:price_max)
      try_add_key.(:length_min)
      try_add_key.(:length_max)
      try_add_key.(:new_used)
      try_add_key.(:tax_status)
      try_add_key.(:ref_no)
      try_add_key.(:exclude_ref_no)
      try_add_key.(:page)
      try_add_key.(:order)
      try_add_key.(:order_col)
      try_add_key.(:order_dir)
      try_add_key.(:currency)
      try_add_key.(:length_unit)
      h
    end

    private

    def normalize_params
      @country_ids = [@country_id] if @country_id
      @country_ids = [@country.id] if @country
      @model_ids = [@model_id] if @model_id
      @manufacturer_ids = [@manufacturer_id] if @manufacturer_id
      @manufacturer_ids = [@manufacturer.id] if @manufacturer
    end

  end
end
