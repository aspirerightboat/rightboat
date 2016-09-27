class FixHashIdsInSavedSearch < ActiveRecord::Migration
  def change
    SavedSearch.find_each do |ss|
      ss.countries = ss.countries.map(&:to_i) if ss.countries.present?
      ss.models = ss.models.map(&:to_i) if ss.models.present?
      ss.manufacturers = ss.manufacturers.map(&:to_i) if ss.manufacturers.present?
      ss.save! if ss.changed?
    end
  end
end
