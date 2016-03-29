class CreateOldSlug < ActiveRecord::Migration
  def up
    create_table :old_slugs do |t|
      t.string :slug
      t.integer :sluggable_id
      t.string :sluggable_type

      t.datetime :created_at
    end

    add_index :old_slugs, [:slug, :sluggable_type]
    add_index :old_slugs, [:sluggable_id]
    add_index :old_slugs, [:sluggable_type]

    drop_table :friendly_id_slugs
  end
end
