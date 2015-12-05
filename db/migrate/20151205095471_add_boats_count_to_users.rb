class AddBoatsCountToUsers< ActiveRecord::Migration
  def up
    add_column :users, :boats_count, :integer, default: 0

    User.reset_column_information
    User.find_each do |u|
      u.update_column :boats_count, u.boats.not_deleted.count
    end
  end

  def down
    remove_column :users, :boats_count
  end
end
