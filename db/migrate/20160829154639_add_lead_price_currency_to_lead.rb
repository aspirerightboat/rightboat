class AddLeadPriceCurrencyToLead < ActiveRecord::Migration
  def up
    add_reference :leads, :lead_price_currency, index: true
    add_column :leads, :lead_price_currency_rate, :float

    Lead.includes(boat: {user: :deal}).find_each do |lead|
      deal = lead.boat.user.deal

      if deal.deal_type == 'standard'
        lead.update_columns(lead_price_currency_id: Currency.default.id, lead_price_currency_rate: 1)
      else
        lead.update_columns(lead_price_currency_id: deal.currency.id, lead_price_currency_rate: deal.currency.rate)
      end
    end

    add_column :deals, :lead_length_rate, :float, default: 1
    remove_column :broker_infos, :lead_length_rate

    add_column :deals, :lead_min_price, :float
    BrokerInfo.find_each { |bi| Deal.where(user_id: bi.user_id).update_all(lead_min_price: bi.lead_min_price) }
    remove_column :broker_infos, :lead_min_price

    add_column :deals, :lead_max_price, :float
    BrokerInfo.find_each { |bi| Deal.where(user_id: bi.user_id).update_all(lead_max_price: bi.lead_max_price) }
    remove_column :broker_infos, :lead_max_price

    RBConfig.repair_key(:charges_text_standard)
  end
end
