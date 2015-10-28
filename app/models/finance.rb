class Finance < ActiveRecord::Base

  belongs_to :user
  belongs_to :manufacturer
  belongs_to :model
  belongs_to :country

  validates_presence_of :user_id, :manufacturer_id, :model_id, :price_currency, :loan_amount_currency
  validates_numericality_of :age_of_vessel, only_integer: true
  validates_numericality_of :price, :loan_amount, allow_blank: true
end
