class AddCaptionToManufacturer < ActiveRecord::Migration[5.0]
  def change
    add_column :manufacturers, :caption, :string
  end
end
