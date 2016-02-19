class CreateExport < ActiveRecord::Migration
  def up
    create_table :exports do |t|
      t.references :user, index: true
      t.string :export_type
      t.string :prefix
      t.boolean :active, default: true
      t.datetime :started_at
      t.datetime :finished_at
      t.string :error_msg

      t.timestamps
    end

    Export.create [
                      {user_id: 18, export_type: 'openmarine'},
                      {user_id: 276, export_type: 'openmarine'},
                      {user_id: 33, export_type: 'openmarine'},
                      {user_id: 52, export_type: 'openmarine'},
                      {user_id: 262, export_type: 'openmarine'},
                  ]
  end
end
