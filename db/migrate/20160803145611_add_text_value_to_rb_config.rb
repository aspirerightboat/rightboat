class AddTextValueToRbConfig < ActiveRecord::Migration
  def up
    add_column :rb_configs, :text_value, :text

    RBConfig.repair
  end
end
