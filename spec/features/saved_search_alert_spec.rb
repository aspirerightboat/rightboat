require 'spec_helper'

RSpec.describe "saved search alert feature" do
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

  let!(:saved_search) { create :saved_search, first_found_boat_id: boat.id }

  context 'new boat is created' do
    let(:updated_save_search) { SavedSearch.last }
    let(:new_boat) { create(:boat, country: country, model: model, manufacturer: manufacturer)}

    it 'updates first_found_boat_id for saved search' do
      allow_any_instance_of(Rightboat::BoatSearch).to receive(:results).and_return([new_boat, boat])
      SavedSearchNoticesJob.new.perform
      expect(updated_save_search.first_found_boat_id).to eq(new_boat.id)
    end
  end
end
