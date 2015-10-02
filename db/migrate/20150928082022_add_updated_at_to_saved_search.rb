class AddUpdatedAtToSavedSearch < ActiveRecord::Migration
  def change
    add_column :saved_searches, :updated_at, :datetime
  end
end
