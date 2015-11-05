module Rightboat

  class BoatSearch
    OrderTypes = %w(score created_at price_desc price_asc year_asc year_desc length_m_desc length_m_asc)

    def initialize(params = {})
      @params = preprocess_param(params)
    end

    def retrieve_boats(includes = nil, per_page = 30)
      match_conidtion = Proc.new do |q, field, param_field|
        param_field ||= field
        q.with field, @params[param_field] if @params[param_field].present?
      end

      includes ||= [:currency, :manufacturer, :model, :primary_image, :vat_rate, :country]
      search = Boat.solr_search(include: includes) do |q|
        q.without :ref_no, @params[:exclude] if @params[:exclude].present?
        q.with :ref_no, @params[:ref_no] if @params[:ref_no].present?
        q.with :live, true
        q.fulltext @params[:q] if @params[:q].present?
        q.paginate page: @params[:page].presence.try(:to_i) || 1, per_page: per_page

        q.order_by @params[:order].to_sym, @params[:order_dir].to_sym if @params[:order]

        # new or used
        if (new_used = @params[:new_used])
          year = Date.today.year
          # q.with :new_boat, true if new_used == :new
          q.with(:year).greater_than_or_equal_to(year) if new_used == :new
          # q.without :new_boat, true if new_used == :used
          q.with(:year).less_than_or_equal_to(year - 1) if new_used == :used
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
        q.with(:price).greater_than_or_equal_to(@params[:price_min]) if @params[:price_min].present?
        q.with(:price).less_than_or_equal_to(@params[:price_max]) if @params[:price_max].present?

        # length
        q.with(:length_m).greater_than_or_equal_to(@params[:length_min]) if @params[:length_min].present?
        q.with(:length_m).less_than_or_equal_to(@params[:length_max]) if @params[:length_max].present?

        # year
        q.with(:year).greater_than_or_equal_to(@params[:year_min]) if @params[:year_min].present?
        q.with(:year).less_than_or_equal_to(@params[:year_max]) if @params[:year_max].present?

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
        boat_type:    :array,
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
        if v.present?
          req_params[field] =
            case type.to_sym
              when :string then v.to_s
              when :float then v.to_f
              when :integer then v.to_i
              when :array
                (v.is_a?(Array) ? v : v.to_s.split(',')).reject(&:blank?)
              when :boolean
                v =~ /^yes|true|1$/i
            end
        end
      end

      # calculate price with default currency
      if req_params[:currency].present?
        c = Currency.cached_by_name(req_params[:currency])
        [:price_min, :price_max].each do |k|
          if req_params[k].present?
            req_params[k] = Currency.convert(req_params[k], c, Currency.default)
          end
        end
      end

      # length is indexed in meter
      if (u = req_params[:length_unit]).present? && (u.to_s.downcase == 'ft')
        [:length_min, :length_max].each do |k|
          if req_params[k].present?
            req_params[k] = (req_params[k] * 0.3048).round(2)
          end
        end
      end

      if (new_used = req_params[:new_used]) && new_used.is_a?(Hash) && new_used.present?
        if new_used['new'] || new_used['used']
          req_params[:new_used] = new_used['new'] ? :new : :used
        end
      end

      if (tax_status = req_params[:tax_status]) && tax_status.is_a?(Hash) && tax_status.present?
        if tax_status['paid'] || tax_status['unpaid']
          req_params[:tax_status] = tax_status['paid'] ? :paid : :unpaid
        end
      end

      page = req_params[:page].to_i
      req_params[:page] = page > 0 ? page : 1

      if req_params[:order]
        if OrderTypes.include?(req_params[:order])
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