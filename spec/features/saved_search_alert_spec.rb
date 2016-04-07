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

  let!(:saved_search) { create :saved_search, user: user, first_found_boat_id: boat.id }

  context 'new boat is created' do
    let(:new_boat) { create(:boat, country: country, model: model, manufacturer: manufacturer)}
    let(:emails) { ActionMailer::Base.deliveries } # here all tests are stored for test env
    let(:last_email) { emails.last }
    let(:updated_save_search) { SavedSearch.last }
    let(:saved_search_alert) { SavedSearchesAlert.where(user_id: user.id).last }
    let(:saved_search_open_email_params) { "token=#{saved_search_alert.token}" }
    let(:image_tag_for_open_email) { /img.*src.*#{saved_search_open_email_params}/ }
    let(:utm_params) { ['utm_medium=email',
                        'utm_source=subscription',
                        'utm_campaign=saved_searches',
                        'utm_content=UserMailer-saved_search_updated'] }

    it 'updates first_found_boat_id for saved search, sends email notification, email includes tracking image for opening mail' do
      allow_any_instance_of(Rightboat::BoatSearch).to receive(:results).and_return([new_boat, boat]) #stub solr

      SavedSearchNoticesJob.new.perform

      expect(updated_save_search.first_found_boat_id).to eq(new_boat.id)
      expect(last_email).to have_body_text image_tag_for_open_email
      expect(last_email.html_part.body.decoded).to include(*utm_params)
    end
  end
end
