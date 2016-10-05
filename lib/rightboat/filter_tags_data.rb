module Rightboat
  class FilterTagsData
    attr_reader :model_infos, :country_infos, :other

    def initialize(search_params)
      @sp = search_params
    end

    def fetch
      @model_infos = Model.where(id: sp.model_ids).order(:name).pluck(:id, :name) if sp.model_ids
      @country_infos = Country.where(id: sp.country_ids).order(:name).pluck(:id, :name) if sp.country_ids
      @other = []
      @other << ['boat_type', sp.boat_type.capitalize] if sp.boat_type
      @other << ['year', "#{sp.year_min || '..'}-#{sp.year_max || '..'}"] if sp.year_min || sp.year_max
      @other << ['price', "#{sp.currency.symbol}#{sp.price_min.to_i || '..'}-#{sp.price_max.to_i || '..'}"] if sp.price_min || sp.price_max
      @other << ['length', "#{sp.length_min.to_i || '..'}-#{sp.length_max.to_i || '..'}#{sp.length_unit}"] if sp.length_min || sp.length_max
      @other << ['q', sp.q] if sp.q
      @other << ['ref_no', sp.ref_no] if sp.ref_no
      @other << ['new_used', sp.new_used.keys.map(&:capitalize).join(' or ')] if sp.new_used
      @other << ['tax_status', sp.tax_status.keys.map(&:capitalize).join(' or ')] if sp.tax_status
      @other = @other.presence

      self
    end

    def any?
      @model_infos || @country_infos || @other
    end

    private

    attr_reader :sp

  end
end
