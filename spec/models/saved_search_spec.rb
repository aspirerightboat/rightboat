require 'spec_helper'

RSpec.describe SavedSearch do
  context '#to_succinct_search_hash' do
    let(:subject) { create :saved_search, price_min: 100,
                             price_max: 200, currency: 'GBP',
                             countries: nil, models: nil,
                             manufacturers: ['1'], q: '' }

    it 'preserves all search attributes' do
      subject = create :saved_search, created_at: 'date', updated_at: 'date', tax_status: {paid: true}, new_used: {used: true}

      expect(subject.to_succinct_search_hash).to include(:year_min, :year_max, :length_min, :length_max, :length_unit,
                                                         :price_min, :price_max, :currency, :order,
                                                         :models, :manufacturers, :ref_no, :boat_type,
                                                         :countries, :tax_status, :new_used, :q)
      expect(subject.to_succinct_search_hash).not_to include(:id, :user_id, :first_found_boat_id, :created_at, :alert, :updated_at)
    end

    it 'strips empty elements' do
      subject = create :saved_search, countries: nil, models: nil, manufacturers: nil, q: ''
      expect(subject.to_succinct_search_hash).not_to include(:q, :countries, :models, :manufacturers)
    end

    it 'strips currency if prices are empty' do
      subject = create :saved_search, price_min: nil, price_max: nil, currency: 'GBP'
      expect(subject.to_succinct_search_hash).not_to include(:price_min, :price_max, :currency)
    end

    it 'preserves currency if prices are not empty' do
      subject = create :saved_search, price_min: 0, price_max: nil, currency: 'GBP'
      expect(subject.to_succinct_search_hash).to include(:price_min, :currency)
      expect(subject.to_succinct_search_hash).not_to include(:price_max)
    end

    it 'strips unit length if length range is empty' do
      subject = create :saved_search, length_min: nil, length_max: nil, length_unit: 'm'
      expect(subject.to_succinct_search_hash).not_to include(:length_min, :length_max, :length_unit)
    end
  end
end
