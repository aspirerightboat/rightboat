class UserActivity < ActiveRecord::Base
  belongs_to :user

  scope :recent_views, -> { where(kind: :boat_view).order(id: :desc) }
  scope :created_leads, -> { where(kind: :lead).order(id: :desc) }
  scope :searches, -> { where(kind: :search).order(id: :desc) }

  def self.create_boat_visit(boat_id:, user_id:, user_email:)
    where(created_at: 1.day.ago..Time.current).find_or_create_by(
      kind: :boat_view,
      boat_id: boat_id,
      user_id:  user_id,
      user_email:  user_email
    )
  end

  def self.create_lead_record(lead_id:, user_id:, user_email:)
    create(
      kind: :lead,
      lead_id: lead_id,
      user_id:  user_id,
      user_email:  user_email
    )
  end

  def self.create_search_record(query:, user_id:, user_email:)
    where(created_at: 1.day.ago..Time.current).find_or_create_by(
      kind: :search,
      query: query,
      user_id:  user_id,
      user_email:  user_email
    )
  end

end
