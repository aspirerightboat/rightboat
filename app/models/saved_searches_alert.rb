class SavedSearchesAlert < ActiveRecord::Base
  serialize :saved_search_ids, Array
  belongs_to :user

  before_create :assign_token

  private

  def assign_token
    self.token = SecureRandom.hex(8)
  end

end
