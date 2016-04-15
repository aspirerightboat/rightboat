require 'spec_helper'

RSpec.describe BoatsController do
  include Devise::TestHelpers
  context '#show' do
    let!(:user) do
      u = create :user
      u.user_alert.saved_searches = true
      u.user_alert.save
      u
    end

    let!(:manufacturer) { create :manufacturer }
    let!(:model) { create :model, manufacturer: manufacturer }
    let!(:country) { create :country }
    let!(:boat) { create :boat, country: country, model: model, manufacturer: manufacturer }
    let!(:saved_search) { create :saved_search, user: user, first_found_boat_id: boat.id }
    let!(:saved_search_alert) { SavedSearchesAlert.create(user_id: user.id, saved_search_ids: [saved_search.id]) }
    let(:mail_click_hash) {
      {
          'user_id' => user.id,
          'url' => sale_boat_path({manufacturer: boat.manufacturer,
                                  model: boat.model,
                                  boat: boat}),
          'action_fullname' => "UserMailer-saved_search_updated",
          'saved_searches_alert_id' => saved_search_alert.id
      }
    }
    let(:show_params) {
      {
          model: model.slug,
          manufacturer: manufacturer.slug,
          boat: boat.slug,
      }
    }

    let(:utm_show_params) {
      show_params.merge(
          utm_medium: 'email',
          utm_source: 'subscription',
          utm_campaign: 'saved_searches',
          utm_content: 'UserMailer-saved_search_updated',
          i: Base64.urlsafe_encode64(user.id.to_s, padding: false),
          token: saved_search_alert.token,
          sent_at: saved_search_alert.created_at.to_date.to_s(:db)
      )
    }

    it "stores mail click entity if utm_params present" do
      get :show, utm_show_params
      expect(response).to be_success

      expect(MailClick.last.attributes).to include mail_click_hash
    end

    it "doesn't store mail click entity for same mail, url, date" do
      get :show, utm_show_params
      get :show, utm_show_params

      expect(MailClick.count).to eq 1
    end

    it "stores mail click entity for same mail, url but different dates" do
      get :show, utm_show_params
      utm_show_params[:sent_at] = (saved_search_alert.created_at + 1.day).to_date.to_s(:db)
      get :show, utm_show_params

      expect(MailClick.count).to eq 2
    end

    it "doesn't store mail click entity for invalid utm params" do
      utm_show_params[:token] = 'invalid_token'
      utm_show_params[:utm_content] = ''
      get :show, utm_show_params

      expect(response).to be_success

      expect(MailClick.count).to eq 0
    end

    it "doesn't store mail click entity if utm_params aren't present" do
      get :show, show_params
      expect(response).to be_success

      expect(MailClick.count).to eq 0
    end

    it "checks if cookie was set to track the leads" do
      get :show, show_params
      expect(response.cookies['tracking_token']).to be_nil

      get :show, utm_show_params
      expect(response.cookies['tracking_token']).to eq(saved_search_alert.token)
    end

  end
end
