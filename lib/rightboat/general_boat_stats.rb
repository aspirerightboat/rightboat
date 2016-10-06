module Rightboat
  class GeneralBoatStats

    attr_reader :price_min, :price_max, :year_min, :year_max, :length_min, :length_max, :country_infos

    def self.fetch
      Rails.cache.fetch('general_boat_stats123', expires_in: 1.hour) { new.fetch }
    end

    def fetch
      # year_min, year_max, price_min, price_max, length_min, length_max = Boat.pluck('MIN(year_built), MAX(year_built), MIN(price), MAX(price), MIN(length_m), MAX(length_m)').first.map(&:to_i)

      search = Boat.retryable_solr_search(retries: 1) do
        with :live, true
        facet :country_id
        stats :year, :price, :length_m
        paginate per_page: 0
      end

      price_stats = search&.stats(:price)
      year_stats = search&.stats(:year)
      length_stats = search&.stats(:length_m)
      raw_country_infos = Country.order(:name).pluck(:id, :name)

      if search
        country_facet_rows = search.facet(:country_id).rows
        country_infos = raw_country_infos.map do |id, name|
          count = country_facet_rows.find { |x| x.value == id }&.count || 0
          [id, name, count]
        end.sort_by(&:third).reverse.map do |id, name, count|
          count = count <= 1000 ? count.to_s : '1000+'
          [id, name, count]
        end
      else
        country_infos = raw_country_infos.map { |id, name| [id, name, nil] }
      end

      meaningful_year_min = Boat.where('year_built > 1000').minimum(:year_built)

      @price_min =  Boat::PRICES_RANGE.min
      @price_max =  (price_stats&.data && price_stats.max&.ceil || Boat::PRICES_RANGE.max).clamp(Boat::PRICES_RANGE)
      @year_min =   (meaningful_year_min || Boat::YEARS_RANGE.min).clamp(Boat::YEARS_RANGE)
      @year_max =   (year_stats&.data && year_stats.max&.ceil || Boat::YEARS_RANGE.max).clamp(Boat::YEARS_RANGE)
      @length_min = (length_stats&.data && length_stats.min&.floor || Boat::M_LENGTHS_RANGE.min).clamp(Boat::M_LENGTHS_RANGE)
      @length_max = (length_stats&.data && length_stats.max&.ceil || Boat::M_LENGTHS_RANGE.max).clamp(Boat::M_LENGTHS_RANGE)
      @country_infos = country_infos

      self
    end

  end
end
