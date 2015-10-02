class RemoveDeletedAtFromFavourites < ActiveRecord::Migration
  def up
    remove_column :favourites, :deleted_at
  end
end
