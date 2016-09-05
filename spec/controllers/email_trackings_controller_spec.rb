require 'spec_helper'

RSpec.describe EmailTrackingsController do
  include Devise::TestHelpers
  context '#saved_search_opened' do
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
    let!(:saved_search_alert) { SavedSearchesAlert.create(user_id: user.id, saved_search_infos: {id: saved_search.id, boat_ids: []}) }

    it "touches 'opened_at'" do
      expect(saved_search_alert.opened_at).to be_nil

      get :saved_search_opened, token: saved_search_alert.token
      expect(response).to be_success
      opened_at = saved_search_alert.reload.opened_at
      expect(opened_at).to_not be_nil

      # try to open it again
      get :saved_search_opened, token: saved_search_alert.token
      expect(response).to be_success
      # opened_at should not be changed
      expect(saved_search_alert.reload.opened_at).to eq opened_at
    end
  end
end
