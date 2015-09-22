class CreateRbConfigs < ActiveRecord::Migration
  def change
    create_table :rb_configs do |t|
      t.string :key
      t.string :value
      t.string :description
    end
  end
end
