require 'spec_helper'

RSpec.describe EnquiriesController do
  include Devise::TestHelpers
  context '#create' do
    let!(:user) do
      u = create :user
      u.user_alert.saved_searches = true
      u.user_alert.save

      u
    end

    let!(:broker) { create :user}
    let!(:broker_info) { create :broker_info, user: broker }

    let!(:manufacturer) { create :manufacturer }
    let!(:model) { create :model, manufacturer: manufacturer }
    let!(:country) { create :country }
    let!(:boat) { create :boat, country: country, model: model, manufacturer: manufacturer, user: broker }
    let!(:saved_search) { create :saved_search, user: user, first_found_boat_id: boat.id }
    let!(:saved_search_alert) { SavedSearchesAlert.create(user_id: user.id, saved_search_ids: [saved_search.id]) }


    let(:utm_params){
      {
        utm_medium: 'email',
        utm_source: 'subscription',
        utm_campaign: 'saved_searches',
        utm_content: 'UserMailer-saved_search_updated',
        i: Base64.urlsafe_encode64(user.id.to_s, padding: false),
        token: saved_search_alert.token,
        sent_at: saved_search_alert.created_at.to_date.to_s(:db)
      }
    }


    it "checks if cookie was set to track the leads, and lead was updated with alert id" do
      sign_in user
      allow(RBConfig).to receive(:[]).with(:lead_price_coef_bound).and_return(500_000)
      allow(RBConfig).to receive(:[]).with(:lead_low_price_coef).and_return(0.0002)
      allow_any_instance_of(BrokerInfo).to receive(:lead_max_price).and_return(300)
      allow_any_instance_of(BrokerInfo).to receive(:lead_min_price).and_return(5)
      allow_any_instance_of(Enquiry).to receive(:handle_lead_created_mails)

      expect(Enquiry.count).to eq(0)

      xhr :post, :create, {id: boat.slug}.merge(utm_params)
      expect(response).to be_success
      expect(response.cookies['tracking_token']).to eq(saved_search_alert.token)
      expect(Enquiry.count).to eq(1)
      expect(Enquiry.last.saved_searches_alert_id).to eq(saved_search_alert.id)

    end

    it "checks that cookie wasn't set and saved_searches_alert_id wasn't set for created lead if no tracking params are present" do
      sign_in user
      allow(RBConfig).to receive(:[]).with(:lead_price_coef_bound).and_return(500_000)
      allow(RBConfig).to receive(:[]).with(:lead_low_price_coef).and_return(0.0002)
      allow_any_instance_of(BrokerInfo).to receive(:lead_max_price).and_return(300)
      allow_any_instance_of(BrokerInfo).to receive(:lead_min_price).and_return(5)
      allow_any_instance_of(Enquiry).to receive(:handle_lead_created_mails)

      expect(Enquiry.count).to eq(0)

      xhr :post, :create, {id: boat.slug}
      expect(response).to be_success
      expect(response.cookies['tracking_token']).to be_nil
      expect(Enquiry.count).to eq(1)
      expect(Enquiry.last.saved_searches_alert_id).to be_nil

    end
  end
end
