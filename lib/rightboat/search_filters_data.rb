module Rightboat
  class SearchFiltersData
    include ParamsReader

    attr_reader :sp, :model_infos_grouped, :country_infos, :model_counts, :country_counts, :state_counts

    def initialize(manufacturer, boat_search)
      @manufacturer = manufacturer
      @search = boat_search.search
      @sp = boat_search.sp
    end

    def fetch
      @model_infos_grouped, @country_infos = model_countries_filters_cached
      @model_counts = @search.facet(:model_id).rows.map { |row| [row.value, row.count] }.to_h
      @country_counts = @search.facet(:country_id).rows.map { |row| [row.value, row.count] }.to_h
      @state_counts = @search.facet(:state).rows.map { |row| [row.value.upcase, row.count] }.to_h
      self
    end

    def show_states_infos?
      sp.country_ids&.one? && sp.country_ids.first == Country::US_COUNTRY_ID
    end

    private

    def model_countries_filters_cached
      Rails.cache.fetch "models_countries_filters_cached_#{@manufacturer.id}", expires_in: 30.minutes do
        [Rightboat::ModelGroup.group_model_infos(fetch_model_infos), fetch_country_infos]
      end
    end

    def fetch_model_infos
      Model.joins(:boats).where(boats: {status: 'active', manufacturer_id: @manufacturer.id})
          .order('models.name')
          .group('models.id, models.slug, models.name')
          .pluck('models.id, models.slug, models.name')
    end

    def fetch_country_infos
      Country.joins(:boats).where(boats: {status: 'active', manufacturer_id: @manufacturer.id})
          .order('countries.name')
          .group('countries.id, countries.slug, countries.name')
          .pluck('countries.id, countries.slug, countries.name')
    end

  end
end
