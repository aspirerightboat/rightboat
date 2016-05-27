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
    let(:emails) { ActionMailer::Base.deliveries } # here all mails are stored for test env
    let(:last_email) { emails.last }
    let(:updated_save_search) { SavedSearch.last }
    let(:saved_search_alert) { SavedSearchesAlert.where(user_id: user.id).last }
    let(:saved_search_open_email_params) { "token=#{saved_search_alert.token}" }
    let(:image_tag_for_open_email) { /img.*src.*#{saved_search_open_email_params}/ }
    let(:utm_params) { ['utm_medium=email',
                        'utm_source=subscription',
                        'utm_campaign=saved_searches',
                        "utm_content=UserMailer-saved_search_updated",
                        "sent_at=#{saved_search_alert.created_at.to_date.to_s(:db)}",
                        "i=#{Base64.urlsafe_encode64(user.id.to_s, padding: false)}"
                      ] }

    it 'updates first_found_boat_id for saved search, sends email notification, email includes tracking image for opening mail' do
      allow_any_instance_of(Rightboat::BoatSearch).to receive(:results).and_return([new_boat, boat]) #stub solr

      Rightboat::SavedSearchNotifier.new.send_mails

      expect(updated_save_search.first_found_boat_id).to eq(new_boat.id)
      expect(last_email).to have_body_text image_tag_for_open_email
    end

    it "user's email contains link with correct utm parameters" do
      allow_any_instance_of(Rightboat::BoatSearch).to receive(:results).and_return([new_boat, boat]) #stub solr

      Rightboat::SavedSearchNotifier.new.send_mails
      document = Nokogiri::HTML(last_email.html_part.body.decoded)

      boat_summary_link = document.xpath("//a[text()='Boat Summary']/@href").text.split('?').last
      expect(boat_summary_link.split('&')).to include(*utm_params)
    end


    context 'mail links to maker/model page' do
        let!(:manufacturer2) { create :manufacturer }
        let!(:model2) { create :model, manufacturer: manufacturer2 }
        let!(:model3) { create :model, manufacturer: manufacturer }

      context 'saved search created from advanced search page' do
        let!(:saved_search) { create :saved_search,
                                     user: user,
                                     first_found_boat_id: boat.id,
                                     manufacturers: [manufacturer, manufacturer2],
                                     models: [model, model2, model3] }

        it "user's email contains link to manufactures page and to models page" do
          allow_any_instance_of(Rightboat::BoatSearch).to receive(:results).and_return([new_boat, boat]) #stub solr

          Rightboat::SavedSearchNotifier.new.send_mails
          document = Nokogiri::HTML(last_email.html_part.body.decoded)

          boat_manufactures_links = document.css("p.manufacturers a").text
          boat_models_links = document.css("p.models a").text

          expect(boat_manufactures_links).to include(manufacturer2.name)
          expect(boat_manufactures_links).to include(manufacturer.name)

          expect(boat_models_links).to include(model.name)
          expect(boat_models_links).to include(model2.name)
          expect(boat_models_links).to include(model3.name)
        end
      end

      context 'saved search created from filters page' do
        let!(:saved_search) { create :saved_search,
                                     user: user,
                                     first_found_boat_id: boat.id,
                                     models: [model.id, model2.id, model3.id] }

        it "user's email contains link to models page and doesn't contain links to manufactures" do
          allow_any_instance_of(Rightboat::BoatSearch).to receive(:results).and_return([new_boat, boat]) #stub solr

          Rightboat::SavedSearchNotifier.new.send_mails
          document = Nokogiri::HTML(last_email.html_part.body.decoded)

          boat_manufactures_links = document.css("p.manufacturers a").text
          boat_models_links = document.css("p.models a").text

          expect(boat_manufactures_links).to eq ""

          expect(boat_models_links).to include(model2.name)
          expect(boat_models_links).to include(model3.name)
          expect(boat_models_links).to include(model.name)
        end
      end

    end
  end
end
