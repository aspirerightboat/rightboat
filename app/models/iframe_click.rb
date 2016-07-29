class IframeClick < ActiveRecord::Base
  belongs_to :broker_iframe

  scope :month_eq, ->(month) { where('MONTH(created_at) = ?', month.to_i) }

  def self.ransackable_scopes(_auth_object = nil)
    [:month_eq]
  end
end
