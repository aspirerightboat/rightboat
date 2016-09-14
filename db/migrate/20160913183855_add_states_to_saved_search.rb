class AddStatesToSavedSearch < ActiveRecord::Migration
  def change
    add_column :saved_searches, :states, :text

    SavedSearch.where('countries = ?', [''].to_yaml).update_all(countries: nil)

    [:year_min, :year_max, :price_min, :price_max, :length_min, :length_max,
     :length_unit, :currency, :ref_no, :q, :boat_type, :order].each do |par|
      cnt = SavedSearch.where("`#{par}` = ''").update_all("`#{par}` = NULL")
      puts "#{par} => #{cnt}"
    end
  end
end
