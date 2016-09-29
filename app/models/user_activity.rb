class UserActivity < ActiveRecord::Base
  KINDS = %w(boat_view lead search forwarded_to_pegasus)

  belongs_to :user
  belongs_to :boat
  belongs_to :lead

  serialize :meta_data, Hash

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

  def self.create_search_record(hash:, user: nil)
    create(
      kind: :search,
      meta_data: hash,
      user_id: user&.id,
      user_email: user&.email
    )
  end

  def self.create_forwarded_to_pegasus(user)
    create!(user: user, user_email: user.email, kind: 'forwarded_to_pegasus')
  end

  def self.favourite_boat_types_for(user)
    boat_ids = recent_views.where(user_id: user.id).pluck(:boat_id)
    types = Boat.where(id: boat_ids).includes(:boat_type).map { |boat| boat.boat_type&.name_stripped }.compact

    group_amount = {}
    types.group_by{ |type| type }.each{ |type, elements| group_amount[type] = elements.size }
    group_amount.max_by{|_, amount| amount }&.first
  end
end
