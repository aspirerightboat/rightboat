# csv fields explained: https://support.google.com/adwords/answer/6053288

module Rightboat
  class GoogleDynamicRemarketing

    def self.generate_csv
      CSV.open(csv_fullpath, 'wb') do |csv|
        csv << [
            'ID',
            'ID2',
            'Item title',
            'Final URL',
            'Image URL',
            'Item subtitle',
            'Item description',
            'Item category',
            'Price',
            'Sale price',
            'Contextual keywords',
            'Item address',
            'Tracking template',
            'Custom parameter',
        ]

        Boat.active.order('id DESC')
            .includes(:manufacturer, :model, :currency, :country, :primary_image, :boat_type, :extra,
                      office: {address: :country}, user: {address: :country})
            .find_each do |boat|
          csv << [
              boat.slug, # ID
              nil, # ID2
              item_title(boat), # Item title
              final_url(boat), # Final URL
              image_url(boat), # Image URL
              item_subtitle(boat), # Item subtitle
              item_description(boat), # Item description
              boat.boat_type&.name, # Item category
              item_price(boat), # Price
              item_price(boat), # Sale price
              nil, # Contextual keywords
              item_address(boat), # Item address
              nil, # Tracking template
              nil, # Custom parameter
          ]
        end
      end
    end

    def self.csv_path
      '/gdr_feed.csv'
    end

    def self.csv_fullpath
      "#{Rails.root}/public#{csv_path}"
    end

    private

    def self.item_title(boat)
      boat.manufacturer_model[0...25]
    end

    def self.item_subtitle(boat)
      boat_or_yacht = (boat.length_m || 0) > 10 ? 'Yacht' : 'Boat'
      "#{boat_or_yacht} for sale"
    end

    def self.image_url(boat)
      boat.primary_image&.file_url(:thumb)
    end

    def self.final_url(boat)
      "#{RIGHTBOAT_DOMAIN_URL}/boats-for-sale/#{boat.manufacturer.slug}/#{boat.model.slug}/#{boat.slug}"
    end

    def self.item_description(boat)
      if (str = boat.extra.short_description)
        str = ActionController::Base.helpers.strip_tags(str)
        str = ActionController::Base.helpers.truncate(str, length: 25)
        str
      end
    end

    def self.item_price(boat)
      if boat.price
        amount = ActionController::Base.helpers.number_to_currency(boat.price, unit: '', precision: 0)
        currency = boat.safe_currency.name
        "#{amount} #{currency}"
      end
    end

    def self.item_address(boat)
      boat.geo_location.presence || boat.full_location.presence || begin
        address = boat.office&.address || boat.user.address
        address&.display_string(:raw)
      end
    end

  end
end
