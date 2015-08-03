module Rightboat

  class BoatSearch
    SortTypes = {
      'Best Match'        => :score,
      'Newly listed'      => :created_at,
      'Price: high - low' => :price_desc,
      'Price: low - high' => :price_asc,
      'Age: high - low'   => :year_asc,
      'Age: low - high'   => :year_desc,
      'LOA: high - low'   => :length_m_desc,
      'LOA: low - high'   => :length_m_asc
    }

    def initialize(params = {})
      @params = preprocess_param(params)
    end

    def retrieve_boats
      match_conidtion = Proc.new do |q, field, param_field|
        param_field ||= field
        q.with field, @params[param_field] unless @params[param_field].blank?
      end

      search = Sunspot.search(Boat) do |q|
        q.with :live, true
        q.fulltext @params[:q] unless @params[:q].blank?
        q.paginate page: @params[:page].to_i, per_page: 30

        q.order_by @params[:order].to_sym, @params[:order_dir].to_sym if @params[:order]

        # new or used
        if (new_used = @params[:new_used])
          q.with :new_boat, true if new_used == :new
          q.without :new_boat, true if new_used == :used
        end

        # tax paid or unpaid
        if (tax_status = @params[:tax_status])
          q.with :tax_paid, true if tax_status == :paid
          q.without :tax_paid, true if tax_status == :unpaid
        end

        # manufacturer or model
        q.any_of do |sq|
          match_conidtion.call(sq, :manufacturer, :manufacturer_model)
          match_conidtion.call(sq, :manufacturer_model)
        end

        # category
        match_conidtion.call(q, :country_id, :country)
        match_conidtion.call(q, :category_id, :category)

        # price
        q.with(:price).greater_than_or_equal_to(@params[:price_min]) unless @params[:price_min].blank?
        q.with(:price).less_than_or_equal_to(@params[:price_max]) unless @params[:price_max].blank?

        # length
        q.with(:length_m).greater_than_or_equal_to(@params[:length_min]) unless @params[:length_min].blank?
        q.with(:length_m).less_than_or_equal_to(@params[:length_max]) unless @params[:length_max].blank?

        # year
        q.with(:year).greater_than_or_equal_to(@params[:year_min]) unless @params[:year_min].blank?
        q.with(:year).less_than_or_equal_to(@params[:year_max]) unless @params[:year_max].blank?

        # fuel type
        match_conidtion.call(q, :fuel_type)
        match_conidtion.call(q, :boat_type)
      end

      search.results
    end

    def preprocess_param(params)
      req_params = params.symbolize_keys
      type_mapping = {
        manufacturer_model: :array,
        category:     :array,
        country:      :array,
        boat_type:    :string,
        fuel_type:    :array,
        price_min:    :float,
        price_max:    :float,
        length_min:   :float,
        length_max:   :float,
        year_min:     :integer,
        year_max:     :integer,
      }
      type_mapping.each do |field, type|
        v = req_params[field]
        unless v.blank?
          req_params[field] =
            case type.to_sym
              when :string then v.to_s
              when :float then v.to_f
              when :integer then v.to_i
              when :array
                (v.is_a?(Array) ? v : v.to_s.split(',')).reject(&:blank?)
              when :boolean
                v =~ /^yes|true|1$/i ? true : false
            end
        end
      end

      # calculate price with default currency
      if !req_params[:currency].blank?
        c = Currency.find_by_name(req_params[:currency])
        [:price_min, :price_max].each do |k|
          unless req_params[k].blank?
            req_params[k] = Currency.convert(req_params[k], c, Currency.default)
          end
        end
      end

      # length is indexed in meter
      if !(u = req_params[:length_unit]).blank? && (u.to_s.downcase == 'ft')
        [:length_min, :length_max].each do |k|
          unless req_params[k].blank?
            req_params[k] = (req_params[k] * 0.3048).round(2)
          end
        end
      end

      if (new_used = req_params[:new_used]) && new_used.is_a?(Hash) && !new_used.blank?
        unless new_used['new'] && new_used['used']
          req_params[:new_used] = new_used['new'] ? :new : :used
        end
      end

      if (tax_status = req_params[:tax_status]) && tax_status.is_a?(Hash) && !tax_status.blank?
        unless tax_status['paid'] && tax_status['unpaid']
          req_params[:tax_status] = tax_status['paid'] ? :paid : :unpaid
        end
      end

      page = req_params[:page].to_i
      req_params[:page] = page > 1 ? page : 1

      if req_params[:order]
        if SortTypes.values.map(&:to_s).include?(req_params[:order])
          req_params[:order_dir] = req_params[:order].to_s =~ /_asc$/ ? :asc : :desc
          req_params[:order] = req_params[:order].gsub(/_(asc|desc)$/, '')
        else
          req_params.delete :order
        end
      end

      req_params
    end
  end

end