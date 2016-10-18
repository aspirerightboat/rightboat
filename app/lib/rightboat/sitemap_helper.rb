module Rightboat
  class SitemapHelper
    # note: it appears that items order in xml doesn't matter, what matters is priority attribute

    def self.boats_with_makemodel_slugs
      Boat.active.order('id DESC').joins(:manufacturer, :model)
          .select('boats.id, boats.slug, boats.updated_at, manufacturers.slug manufacturer_slug, models.slug model_slug')
    end

    def self.active_manufacturer_slugs
      Manufacturer.joins(:boats).where(boats: {status: :active})
          .group('manufacturers.slug').order('COUNT(*) DESC')
          .pluck('manufacturers.slug')
    end

    def self.active_makemodel_slugs
      Model.joins(:boats).where(boats: {status: :active})
          .joins(:manufacturer)
          .group('manufacturers.slug, models.slug').order('COUNT(*) DESC')
          .pluck('manufacturers.slug, models.slug')
    end

  end
end
