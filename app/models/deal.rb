class Deal < ActiveRecord::Base
  DEAL_TYPES = %w(standard flat_lead flat_month)

  belongs_to :user
  belongs_to :currency

  def setup_flat_lead_deal!(currency)
    self.deal_type = 'flat_lead'
    self.currency = currency
    self.flat_lead_price ||= RBConfig[:default_flat_lead_price]
    save!
  end
end
