class CombineSavedSearchParams < ActiveRecord::Migration
  def up
    rename_column :saved_searches, :country, :countries
    add_column :saved_searches, :manufacturers, :text

    SavedSearch.reset_column_information

    SavedSearch.all.each do |ss|
      if ss.model
        model = Model.where(name: ss.model).first
        ss.models = [model.id.to_s] if model
      end
      if ss.manufacturer
        manufacturer = Manufacturer.where(name: ss.manufacturer).first
        ss.manufacturers = [manufacturer.id.to_s] if manufacturer
      end
      ss.save! if ss.changed?
    end

    remove_column :saved_searches, :model
    remove_column :saved_searches, :manufacturer
    remove_column :saved_searches, :category
  end
end
