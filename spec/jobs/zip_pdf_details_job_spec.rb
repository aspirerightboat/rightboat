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
  end

end
