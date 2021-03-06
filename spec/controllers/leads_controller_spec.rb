require 'spec_helper'

RSpec.describe LeadsController do
  include Devise::TestHelpers
  let!(:broker) { create :user}
  let!(:broker_info) { create :broker_info, user: broker }

  let!(:manufacturer) { create :manufacturer }
  let!(:model) { create :model, manufacturer: manufacturer }
  let!(:country) { create :country }

  context '#create' do
    let!(:user) do
      u = create :user
      u.user_alert.saved_searches = true
      u.user_alert.save

      u
    end

    let!(:boat) { create :boat, country: country, model: model, manufacturer: manufacturer, user: broker }
    let!(:saved_search) { create :saved_search, user: user, first_found_boat_id: boat.id }
    let!(:saved_search_alert) { SavedSearchesAlert.create(user_id: user.id, saved_search_infos: {id: saved_search.id, boat_ids: []}) }


    let(:utm_params) {
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
      allow_any_instance_of(Lead).to receive(:handle_lead_created_mails)

      expect(Lead.count).to eq(0)

      xhr :post, :create, {id: boat.slug}.merge(utm_params)
      expect(response).to be_success
      expect(response.cookies['tracking_token']).to eq(saved_search_alert.token)
      expect(Lead.count).to eq(1)
      expect(Lead.last.saved_searches_alert_id).to eq(saved_search_alert.id)

    end

    it "checks that cookie wasn't set and saved_searches_alert_id wasn't set for created lead if no tracking params are present" do
      sign_in user
      allow(RBConfig).to receive(:[]).with(:lead_price_coef_bound).and_return(500_000)
      allow(RBConfig).to receive(:[]).with(:lead_low_price_coef).and_return(0.0002)
      allow_any_instance_of(BrokerInfo).to receive(:lead_max_price).and_return(300)
      allow_any_instance_of(BrokerInfo).to receive(:lead_min_price).and_return(5)
      allow_any_instance_of(Lead).to receive(:handle_lead_created_mails)

      expect(Lead.count).to eq(0)

      xhr :post, :create, {id: boat.slug}
      expect(response).to be_success
      expect(response.cookies['tracking_token']).to be_nil
      expect(Lead.count).to eq(1)
      expect(Lead.last.saved_searches_alert_id).to be_nil

    end
  end

  context '#signup_and_view_pdf' do
    let!(:user) { create :user }

    let!(:boat1) { create :boat, country: country, model: model, manufacturer: manufacturer, user: broker }
    let!(:boat2) { create :boat, country: country, model: model, manufacturer: manufacturer, user: broker }

    it 'fills user phone at registration if we know it from previous leads' do
      allow(RBConfig).to receive(:[]).with(:lead_price_coef_bound).and_return(500_000)
      allow(RBConfig).to receive(:[]).with(:lead_low_price_coef).and_return(0.0002)
      allow(RBConfig).to receive(:[]).with(:lead_gap_minutes).and_return(0)
      allow_any_instance_of(BrokerInfo).to receive(:lead_max_price).and_return(300)
      allow_any_instance_of(BrokerInfo).to receive(:lead_min_price).and_return(5)
      allow_any_instance_of(Lead).to receive(:handle_lead_created_mails)

      expect(Lead.count).to eq(0)

      xhr :post, :create, {id: boat1.slug,
                           utf8: '✓',
                           has_account: 'false',
                           title: 'Mr',
                           first_name: 'Forename',
                           surname: 'Surname',
                           email: 'test-email@gmail.com',
                           password: '',
                           country_code: '44',
                           phone: '8765432',
                           message: ''}
      expect(response).to be_success
      expect(Lead.count).to eq(1)

      xhr :post, :create, {id: boat2.slug,
                           utf8: '✓',
                           has_account: 'false',
                           title: 'Mr',
                           first_name: 'Forename',
                           surname: 'Surname',
                           email: 'test-email@gmail.com',
                           password: '',
                           country_code: '',
                           phone: '',
                           message: ''}
      expect(response).to be_success
      expect(Lead.count).to eq(2)

      post :signup_and_view_pdf, {utf8: '✓',
                                  email: 'test-email@gmail.com',
                                  title: 'Mr',
                                  first_name: 'Forename',
                                  last_name: 'Surname',
                                  phone: '',
                                  boat_id: boat2.slug,
                                  password: '12345678',
                                  password_confirmation: '12345678'}
      expect(response).to be_success
      expect(User.last.email).to eq('test-email@gmail.com')
      expect(User.last.phone).to eq('44-8765432')
    end
  end

end
