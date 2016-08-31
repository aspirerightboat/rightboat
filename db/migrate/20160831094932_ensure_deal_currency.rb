class EnsureDealCurrency < ActiveRecord::Migration
  def up
    Deal.includes(:user).where(currency_id: nil).each do |deal|
      currency = Currency.deal_currency_by_country(deal.user.country&.iso)
      deal.update(currency: currency)
    end
  end
end
