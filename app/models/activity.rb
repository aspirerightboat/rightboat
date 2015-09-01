class Activity
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user

  field :action,      type: String
  field :target_id,   type: String
  field :ip,          type: String
  field :user_id,     type: Integer
  field :parameters,  type: Hash
  field :count,       type: Integer, default: 1

  validates_presence_of :action, :ip

  default_scope -> { order(count: :desc) }
end
