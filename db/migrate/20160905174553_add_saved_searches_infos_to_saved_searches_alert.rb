class AddSavedSearchesInfosToSavedSearchesAlert < ActiveRecord::Migration
  def up
    add_column :saved_searches_alerts, :saved_search_infos, :text

    SavedSearchesAlert.find_each do |ssa|
      ssa.saved_search_infos = ssa.saved_search_ids.map { |id| {id: id, boat_ids: []} }
      ssa.save!
    end
  end
end
