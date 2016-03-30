class SavedSearchesAlert < ActiveRecord::Base
  serialize :saved_search_ids, Array
end
