class CreateBatchUploadJobs < ActiveRecord::Migration
  def change
    create_table :batch_upload_jobs do |t|
      t.string :status, default: :pending
      t.string :url, default: nil
      t.timestamps
    end
  end
end
