require 'spec_helper'

RSpec.describe SavedSearch do
  context '#to_succinct_search_hash' do
    let(:subject) { create :saved_search, price_min: 100,
                             price_max: 200, currency: 'GBP',
                             countries: nil, models: nil,
                             manufacturers: ['1'], q: '' }

    it 'preserves all search attributes' do
      subject = create :saved_search, year_min: 2008, year_max: 2009, length_min: 0, length_max: 10, length_unit: 'm',
                       price_min: 100, price_max: 200, currency: 'GBP', order: 'price_asc',
                       models: ['2'], manufacturers: ['1'], q: 'query', ref_no: 'RB12312', first_found_boat_id: 1, created_at: 'date',
                       updated_at: 'date', boat_type: 'Power', countries:['90'], tax_status: {paid: true}, new_used: {used: true}

      expect(subject.to_succinct_search_hash).to include(year_min: 2008, year_max: 2009, length_min: 0, length_max: 10, length_unit: 'm',
                                                         price_min: 100, price_max: 200, currency: 'GBP', order: 'price_asc',
                                                         models: ['2'], manufacturers: ['1'], ref_no: 'RB12312', boat_type: 'Power',
                                                         countries:['90'], tax_status: {paid: true}, new_used: {used: true}), q: 'query'
      expect(subject.to_succinct_search_hash).not_to include(:id, :user_id, :first_found_boat_id, :created_at, :alert, :updated_at)
    end

    it 'strips empty elements' do
      subject = create :saved_search, price_min: 100, price_max: 200, currency: 'GBP', countries: nil, models: nil, manufacturers: nil, q: ''
      expect(subject.to_succinct_search_hash).to include(:price_min, :price_max, :currency)
      expect(subject.to_succinct_search_hash).not_to include(:q, :countries, :models, :manufacturers)
    end

    it 'strips currency if prices are empty' do
      subject = create :saved_search, year_min: 2008, year_max: 2009, length_min: 0, length_max: 10, length_unit: 'm',
                       price_min: nil, price_max: nil, currency: 'GBP', order: 'price_asc',
                       models: ['2'], manufacturers: ['1'], q: 'query', ref_no: 'RB12312', first_found_boat_id: 1, created_at: 'date',
                       updated_at: 'date', boat_type: 'Power', countries:['90'], tax_status: {paid: true}, new_used: {used: true}
      expect(subject.to_succinct_search_hash).not_to include(:price_min, :price_max, :currency)
    end

    it 'preserves currency if prices are not empty' do
      subject = create :saved_search, year_min: 2008, year_max: 2009, length_min: 0, length_max: 10, length_unit: 'm',
                       price_min: 0, price_max: nil, currency: 'GBP', order: 'price_asc',
                       models: ['2'], manufacturers: ['1'], q: 'query', ref_no: 'RB12312', first_found_boat_id: 1, created_at: 'date',
                       updated_at: 'date', boat_type: 'Power', countries:['90'], tax_status: {paid: true}, new_used: {used: true}
      expect(subject.to_succinct_search_hash).to include(:price_min, :currency)
    end

    it 'strips unit length if length range is empty' do
      subject = create :saved_search, year_min: 2008, year_max: 2009, length_min: nil, length_max: nil, length_unit: 'm',
                       price_min: nil, price_max: nil, currency: 'GBP', order: 'price_asc',
                       models: ['2'], manufacturers: ['1'], q: 'query', ref_no: 'RB12312', first_found_boat_id: 1, created_at: 'date',
                       updated_at: 'date', boat_type: 'Power', countries:['90'], tax_status: {paid: true}, new_used: {used: true}
      expect(subject.to_succinct_search_hash).not_to include(:length_min, :length_max, :length_unit)
    end
  end
end
