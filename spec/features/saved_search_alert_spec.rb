require 'spec_helper'

RSpec.describe "saved search alert feature" do
  let!(:user) do
    u = create :user
    u.user_alert.saved_searches = true
    u.user_alert.save
    u
  end
  let!(:country) { create :country }
  let!(:manufacturer) { create :manufacturer }
  let!(:model) { create :model, manufacturer: manufacturer }
  let!(:drive_type) { create :drive_type }
  let!(:engine_manufacturer) { create :engine_manufacturer }
  let!(:engine_model) { create :engine_model, engine_manufacturer: engine_manufacturer }
  let!(:vat_rate) { create :vat_rate }
  let!(:fuel_type) { create :fuel_type }
  let!(:currency) { create :currency }
  let!(:boat_type) { create :boat_type }
  let!(:boat_category) { create :boat_category }
  let!(:boat) do
    create :boat,
           user: user,
           category: boat_category,
           boat_type: boat_type,
           currency: currency,
           engine_model: engine_model,
           engine_manufacturer: engine_manufacturer,
           drive_type: drive_type,
           model: model,
           manufacturer: manufacturer,
           country: country,
           fuel_type: fuel_type,
           vat_rate: vat_rate
  end

  let!(:saved_search) { create :saved_search, manufacturer: manufacturer, first_found_boat_id: boat.id }

  context 'new boat is created' do
    let(:updated_save_search) { SavedSearch.last }

    it 'updates first_found_boat_id for saved search' do
      new_boat = create(:boat,
             user: user,
             category: boat_category,
             boat_type: boat_type,
             currency: currency,
             engine_model: engine_model,
             engine_manufacturer: engine_manufacturer,
             drive_type: drive_type,
             model: model,
             manufacturer: manufacturer,
             country: country,
             fuel_type: fuel_type,
             vat_rate: vat_rate)

      allow_any_instance_of(Rightboat::BoatSearch).to receive(:results).and_return([new_boat, boat])

      SavedSearchNoticesJob.new.perform

      expect(updated_save_search.first_found_boat_id).to eq(new_boat.id)
    end
  end
end
