class UserActivity < ActiveRecord::Base
  belongs_to :user
  belongs_to :boat
  belongs_to :lead

  scope :recent_views, -> { where(kind: :boat_view).order(id: :desc) }
  scope :created_leads, -> { where(kind: :lead).order(id: :desc) }
  scope :searches, -> { where(kind: :search).order(id: :desc) }
  scope :recent, ->(limit = nil) { order(id: :desc).limit(limit) }

  def self.create_boat_visit(boat_id:, user: nil)
    create(
      kind: :boat_view,
      boat_id: boat_id,
      user_id:  user&.id,
      user_email:  user&.email
    )
  end

  def self.create_lead_record(lead_id:, user: nil)
    create(
      kind: :lead,
      lead_id: lead_id,
      user_id:  user&.id,
      user_email:  user&.email
    )
  end

  def self.create_search_record(query:, user: nil)
    create(
      kind: :search,
      query: query,
      user_id:  user&.id,
      user_email:  user&.email
    )
  end

end
