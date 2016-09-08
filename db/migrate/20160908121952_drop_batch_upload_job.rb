class DropBatchUploadJob < ActiveRecord::Migration
  def change
    drop_table :batch_upload_jobs
  end
end
