class AddCurrencyRateToEnquiry < ActiveRecord::Migration
  def up
    add_column :enquiries, :boat_currency_rate, :float
    add_column :enquiries, :eur_rate, :float

    Enquiry.reset_column_information

    eur_rate = Currency.where(name: 'EUR').first.rate
    Enquiry.not_deleted.includes(boat: :currency).find_each do |lead|
      lead.eur_rate = eur_rate
      lead.boat_currency_rate = (lead.boat.currency || Currency.default).rate
      lead.save!
    end
  end
end
