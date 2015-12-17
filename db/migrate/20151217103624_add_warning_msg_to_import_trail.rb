class AddWarningMsgToImportTrail < ActiveRecord::Migration
  def change
    add_column :import_trails, :warning_msg, :string
  end
end
