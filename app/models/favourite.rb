class Favourite < ActiveRecord::Base

  self.table_name = 'saved_boats'

  belongs_to :boat, inverse_of: :favourites
  belongs_to :user, inverse_of: :favourites

  validates_presence_of :boat_id, :user_id
  validates_uniqueness_of :boat_id, scope: :user_id

  def display_ts
    created_at.try{|ts| ts.strftime('%d/%m/%Y')}
  end
end