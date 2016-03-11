class CreateErrorEvent < ActiveRecord::Migration
  def change
    create_table :error_events do |t|
      t.string :error_type
      t.text :message
      t.text :backtrace
      t.text :context
      t.boolean :notified, default: false

      t.timestamps
    end
  end
end
