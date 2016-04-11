class AddModelsToSavedSearch < ActiveRecord::Migration
  def change
    add_column :saved_searches, :models, :text
  end
end
