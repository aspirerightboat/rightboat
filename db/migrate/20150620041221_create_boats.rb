class CreateBoats < ActiveRecord::Migration
  def change
    create_table :boats do |t|
      t.string      :name
      t.datetime    :deleted_at
      t.boolean     :new_boat, default: false
      t.boolean     :featured
      t.boolean     :recently_reduced
      t.boolean     :poa
      t.boolean     :under_offer
      t.string      :source_id
      t.string      :source_url, limit: 512
      t.string      :location
      t.string      :geo_location
      t.integer     :year_built
      t.float       :price
      t.float       :length_m
      t.string      :slug
      t.text        :description
      t.text        :owners_comment
      t.references  :user,                index: true, foreign_key: true
      t.references  :boat_type,           index: true, foreign_key: true
      t.references  :import,              index: true, foreign_key: true
      t.references  :office,              index: true, foreign_key: true
      t.references  :manufacturer,        index: true, foreign_key: true
      t.references  :model,               index: true, foreign_key: true
      t.references  :country,             index: true, foreign_key: true
      t.references  :currency,            index: true, foreign_key: true
      t.references  :drive_type,          index: true, foreign_key: true
      t.references  :engine_manufacturer, index: true, foreign_key: true
      t.references  :engine_model,        index: true, foreign_key: true
      t.references  :vat_rate,            index: true, foreign_key: true
      t.references  :fuel_type,           index: true, foreign_key: true

      t.timestamps null: false
    end

    add_index :boats, :featured
    add_index :boats, :source_id
    add_index :boats, :slug
  end
end
