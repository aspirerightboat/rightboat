require 'spec_helper'

RSpec.describe ZipPdfDetailsJob do
  let!(:broker) { create :user }
  let!(:broker_info) { create :broker_info, user: broker }
  let!(:manufacturer) { create :manufacturer }
  let!(:model) { create :model, manufacturer: manufacturer }
  let!(:country) { create :country }
  let!(:boats) { create_list(:boat, 3, country: country, model: model, manufacturer: manufacturer, user: broker) }
  let!(:job) { create(:batch_upload_job) }

  context '#perform' do
    let(:subject) { described_class.new(job_id: job.id, boats_refs: boats.map(&:ref_no)) }

    it 'raises error if job is not found' do
      expect { described_class.new(job_id: 'invalid', boats_refs: boats.map(&:ref_no)) }.to raise_error 'Job Not Found'
    end

    it 'finds boats and job by params' do
      subject.perform
      expect(subject.boats).to include(*boats)
      expect(subject.job).to eq(job)
    end
  end

end
