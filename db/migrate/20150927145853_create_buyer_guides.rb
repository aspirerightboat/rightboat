class CreateBuyerGuides < ActiveRecord::Migration
  def change
    create_table :buyer_guides do |t|
      t.integer  :article_author_id
      t.integer  :manufacturer_id
      t.integer  :model_id
      t.string   :slug
      t.text     :body
      t.string   :short_description
      t.text     :zcard_desc
      t.string   :photo
      t.string   :thumbnail
      t.boolean  :published,          default: false

      t.timestamps
    end

    add_index :buyer_guides, :slug
    add_index :buyer_guides, :article_author_id
    add_index :buyer_guides, :manufacturer_id
    add_index :buyer_guides, :model_id
  end
end
