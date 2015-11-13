class AddKindToRbConfigs < ActiveRecord::Migration
  def change
    add_column :rb_configs, :kind, :string

    RBConfig.reset_column_information

    defaults = RBConfig.defaults
    RBConfig.find_each do |config|
      config.kind = defaults.find { |row| row[:key] == config.key }[:kind]
      config.save!
    end
  end
end
