module Rightboat
  class BoatSearch
    PER_PAGE = 30

    attr_reader :search, :sp

    def do_search(params: nil, search_params: nil,
                  includes: [:currency, :manufacturer, :model, :primary_image, :vat_rate, :country],
                  per_page: PER_PAGE,
                  with_facets: nil)
      @sp = search_params || SearchParams.new(params).read

      @search = Boat.retryable_solr_search!(include: includes) do
        if sp.q
          q = exact_q_search_if_makemodel(sp.q)
          fulltext q do
            minimum_match 1
          end
        end
        with :live, true
        with :ref_no, sp.ref_no if sp.ref_no
        without :ref_no, sp.exclude_ref_no if sp.exclude_ref_no
        paginate page: sp.page, per_page: per_page
        order_by sp.order_col, sp.order_dir if sp.order

        if sp.new_used
          any_of do
            with :new_boat, true if sp.new_used[:new]
            with :new_boat, false if sp.new_used[:used]
          end
        end

        if sp.tax_status
          any_of do
            with :tax_paid, true if sp.tax_status[:paid]
            with :tax_paid, false if sp.tax_status[:unpaid]
          end
        end

        if sp.manufacturer_model
          any_of do
            with :manufacturer, sp.manufacturer_model
            with :manufacturer_model, sp.manufacturer_model
          end
        end

        any_of { sp.manufacturer_ids.each { |manufacturer_id| with :manufacturer_id, manufacturer_id } } if sp.manufacturer_ids
        model_ids_filter = (any_of { sp.model_ids.each { |model_id| with :model_id, model_id } } if sp.model_ids)
        country_ids_filter = (any_of { sp.country_ids.each { |country_id| with :country_id, country_id } } if sp.country_ids)
        states_filter = (any_of { sp.downcase_states.each { |state| with :state, state } } if sp.states)

        with(:boat_type_id, sp.boat_type_id) if sp.boat_type_id
        with :boat_type, sp.boat_type if sp.boat_type

        with(:price).greater_than_or_equal_to(gbp_price(sp.price_min)) if sp.price_min
        with(:price).less_than_or_equal_to(gbp_price(sp.price_max)) if sp.price_max

        with(:length_m).greater_than_or_equal_to(sp.length_min) if sp.length_min
        with(:length_m).less_than_or_equal_to(sp.length_max) if sp.length_max

        with(:year).greater_than_or_equal_to(sp.year_min) if sp.year_min
        with(:year).less_than_or_equal_to(sp.year_max) if sp.year_max

        # any_of { category.each { |category_id| with :category_id, category_id } } if category

        if with_facets
          facet :country_id, exclude: country_ids_filter
          facet :model_id, exclude: model_ids_filter
          facet :state, exclude: states_filter
        end
      end

      self
    end

    def results
      @search.results
    end

    def hits
      @search.hits
    end

    private

    def gbp_price(price)
      Currency.convert(price, sp.currency, Currency.default)
    end

    def exact_q_search_if_makemodel(q)
      if !sp.manufacturer_ids && !sp.model_ids && is_makemodel_or_model_str(q)
        %("#{q}")
      else
        q
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
