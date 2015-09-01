class Activity
  include Mongoid::Document
  include Mongoid::Timestamps

  field :action,      type: String
  field :target_id,   type: String
  field :ip,          type: String
  field :user_id,     type: Integer
  field :parameters,  type: Hash
  field :count,       type: Integer, default: 1

  validates_presence_of :action

  scope :recent, ->   { order(updated_at: :desc) }
  scope :popular, ->  { order(count: :desc) }
  scope :show, ->     { where(action: :show) }
  scope :search, ->   { where(action: :search) }
end
