class CreateBatchUploadJobs < ActiveRecord::Migration
  def change
    create_table :batch_upload_jobs do |t|
      t.string :status, default: :processing
      t.string :url, default: ''
      t.timestamps
    end
  end
end
