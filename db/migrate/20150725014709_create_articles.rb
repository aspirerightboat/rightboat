class CreateArticles < ActiveRecord::Migration
  def change
    create_table :article_categories do |t|
      t.string   :name, index: true
      t.string   :slug, index: true
      t.integer  :articles_count, default: 0

      t.timestamps
    end

    create_table :article_authors do |t|
      t.string   :title
      t.string   :name, index: true
      t.text     :description
      t.string   :photo
      t.string   :google_plus_link
      t.string   :twitter_handle
      t.string   :slug, index: true
      t.integer  :articles_count, default: 0

      t.timestamps
    end

    create_table :articles do |t|
      t.string   :title
      t.text     :short
      t.text     :full
      t.string   :image
      t.boolean  :frontpage,            default: false
      t.boolean  :live,                 default: false
      t.string   :slug,                 index: true
      t.references :article_category,   index: true, foreign_key: true
      t.references :article_author,     index: true, foreign_key: true

      t.timestamps
    end

  end
end
