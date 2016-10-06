module Rightboat
  class FilterTagsData
    attr_reader :model_infos, :country_infos, :state_infos, :other

    def initialize(search_params)
      @sp = search_params
    end

    def fetch
      @model_infos = Model.where(id: sp.model_ids).order(:name).pluck(:id, :name) if sp.model_ids
      @country_infos = Country.where(id: sp.country_ids).order(:name).pluck(:id, :name) if sp.country_ids
      @state_infos = Rightboat::USStates.states_map.slice(*sp.states) if sp.states
      @other = []
      @other << ['boat_type', sp.boat_type.capitalize] if sp.boat_type
      @other << ['year', format_year_range] if sp.year_min || sp.year_max
      @other << ['price', format_price_range] if sp.price_min || sp.price_max
      @other << ['length', format_length_range] if sp.length_min || sp.length_max
      @other << ['q', sp.q] if sp.q
      @other << ['ref_no', sp.ref_no] if sp.ref_no
      @other << ['new_used', format_new_used] if sp.new_used
      @other << ['tax_status', format_tax_status] if sp.tax_status
      @other = @other.presence

      self
    end

    def any?
      @model_infos || @country_infos || @other
    end

    private

    attr_reader :sp

    def format_year_range
      "#{sp.year_min || '..'}-#{sp.year_max || '..'}"
    end

    def format_price_range
      h = ActionController::Base.helpers
      price_sym = sp.currency.symbol
      price_min = (h.number_to_currency(sp.price_min, unit: '', precision: 0) if sp.price_min)
      price_max = (h.number_to_currency(sp.price_max, unit: '', precision: 0) if sp.price_max)
      "#{price_sym}#{price_min || '..'}-#{price_max || '..'}"
    end

    def format_length_range
      "#{sp.length_min.to_i || '..'}-#{sp.length_max.to_i || '..'}#{sp.length_unit}"
    end

    def format_tax_status
      sp.tax_status.keys.map(&:capitalize).join(' or ')
    end

    def format_new_used
      sp.new_used.keys.map(&:capitalize).join(' or ')
    end

  end
end
