require 'spec_helper'

RSpec.describe BoatsController do
  let!(:manufacturer) { create :manufacturer }
  let!(:model) { create :model, manufacturer: manufacturer }
  let!(:currency) { create :currency }
  let!(:boat_without_country) { create :boat, country: nil, model: model, manufacturer: manufacturer, currency: currency }
  let!(:currency_gbp) { create :currency, :gbp }

  context '#show' do
    render_views

    it 'should show boat page for boat without country' do
      expect(boat_without_country.country).to be_nil
      get :show, {model: model, manufacturer: manufacturer, boat: boat_without_country}
      expect(response).to be_success
      doc = Nokogiri::HTML(response.body)
      expect(doc.at_css('.boat-specs')).to be_present
    end

  end
end
