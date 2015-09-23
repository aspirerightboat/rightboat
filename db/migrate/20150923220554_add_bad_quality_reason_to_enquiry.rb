class AddBadQualityReasonToEnquiry < ActiveRecord::Migration
  def change
    add_column :enquiries, :bad_quality_reason, :string
    add_column :enquiries, :bad_quality_comment, :text
  end
end
